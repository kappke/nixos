import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland only: lists outputs and applies layouts through `hyprctl eval` (Lua config API).
// Layouts are runtime-only; kanshi is stopped while they apply and restarted on the next hotplug.
Item {
    id: root

    property var monitors: []
    // "extend" or "mirror"; derived from the compositor state.
    property string layout: "extend"
    // Where the secondary outputs go relative to the primary one when extending.
    property string placement: "right"

    readonly property var enabledMonitors: root.monitors.filter(function(m) { return !m.disabled; })
    readonly property var primary: root.pickPrimary(root.monitors)

    function isInternal(name) {
        return /^(eDP|LVDS|DSI)/.test(name);
    }

    // The first external output leads; the laptop panel is only primary when alone.
    function pickPrimary(list) {
        for (const m of list) {
            if (!root.isInternal(m.name))
                return m;
        }
        return list.length > 0 ? list[0] : null;
    }

    function refresh() {
        listProcess.exec(listProcess.command);
    }

    function parse(output) {
        if (!output || output.trim().length === 0)
            return;

        try {
            const list = JSON.parse(output).map(function(m) {
                return {
                    name: m.name,
                    description: m.description || "",
                    width: m.width,
                    height: m.height,
                    refreshRate: m.refreshRate,
                    scale: m.scale,
                    disabled: m.disabled,
                    mirrorOf: m.mirrorOf,
                    internal: root.isInternal(m.name)
                };
            });
            root.monitors = list;
            root.layout = list.some(function(m) { return !m.disabled && m.mirrorOf !== "none"; }) ? "mirror" : "extend";

            if (root.recovering) {
                root.recovering = false;
                root.restoreInternal();
            }
        } catch (error) {
            // hyprctl can fail while the compositor reloads; keep the last valid list.
        }
    }

    // Unplugging the last external output must not leave the laptop panel switched off.
    property bool recovering: false

    function restoreInternal() {
        const hidden = root.monitors.filter(function(m) { return m.disabled && root.isInternal(m.name); });
        const external = root.monitors.some(function(m) { return !m.disabled && !root.isInternal(m.name); });
        if (external || hidden.length === 0)
            return;

        root.run(hidden.map(function(m) {
            return root.monitorLua(m.name, { mode: '"preferred"', position: '"0x0"', scale: m.scale, mirror: '""', disabled: "false" });
        }));
    }

    function monitorLua(name, fields) {
        const parts = ['output = "' + name + '"'];
        for (const key in fields)
            parts.push(key + " = " + fields[key]);
        return "hl.monitor({ " + parts.join(", ") + " })";
    }

    // kanshi re-applies its profile as soon as the layout drifts from it, which undoes
    // manual changes (a switched-off output could never be turned back on). Stop it while
    // the layout is managed here; hotplug starts it again.
    function run(statements) {
        Quickshell.execDetached(["sh", "-c", 'systemctl --user stop kanshi; exec hyprctl eval "$1"', "sh", statements.join("\n")]);
        refreshTimer.restart();
    }

    function logicalSize(m) {
        return { w: Math.round(m.width / m.scale), h: Math.round(m.height / m.scale) };
    }

    // Primary first, then the others, laid out on one side of it.
    function extend() {
        const primary = root.primary;
        if (!primary)
            return;

        const others = root.monitors.filter(function(m) { return m.name !== primary.name; });
        const statements = [root.monitorLua(primary.name, {
            mode: '"preferred"', position: '"0x0"', scale: primary.scale, mirror: '""', disabled: "false"
        })];

        const size = root.logicalSize(primary);
        let offset = 0;
        for (const m of others) {
            const own = root.logicalSize(m);
            let x = 0;
            let y = 0;
            switch (root.placement) {
            case "left":
                offset -= own.w;
                x = offset;
                break;
            case "above":
                offset -= own.h;
                y = offset;
                break;
            case "below":
                y = size.h + offset;
                offset += own.h;
                break;
            default:
                x = size.w + offset;
                offset += own.w;
            }
            statements.push(root.monitorLua(m.name, {
                mode: '"preferred"', position: '"' + x + "x" + y + '"', scale: m.scale, mirror: '""', disabled: "false"
            }));
        }
        root.run(statements);
    }

    function mirror() {
        const primary = root.primary;
        if (!primary)
            return;

        const statements = [root.monitorLua(primary.name, {
            mode: '"preferred"', position: '"0x0"', scale: primary.scale, mirror: '""', disabled: "false"
        })];
        for (const m of root.monitors) {
            if (m.name === primary.name)
                continue;
            statements.push(root.monitorLua(m.name, {
                mode: '"preferred"', position: '"auto"', scale: m.scale, mirror: '"' + primary.name + '"', disabled: "false"
            }));
        }
        root.run(statements);
    }

    function only(name) {
        const statements = [];
        for (const m of root.monitors) {
            if (m.name === name) {
                statements.push(root.monitorLua(m.name, {
                    mode: '"preferred"', position: '"0x0"', scale: m.scale, mirror: '""', disabled: "false"
                }));
            } else {
                statements.push(root.monitorLua(m.name, { disabled: "true" }));
            }
        }
        root.run(statements);
    }

    function toggle(name) {
        const target = root.monitors.find(function(m) { return m.name === name; });
        if (!target)
            return;

        // Never switch off the last active output.
        if (!target.disabled && root.enabledMonitors.length <= 1)
            return;

        root.run([target.disabled
            ? root.monitorLua(name, { mode: '"preferred"', position: '"auto"', scale: target.scale, mirror: '""', disabled: "false" })
            : root.monitorLua(name, { disabled: "true" })]);
    }

    Process {
        id: listProcess

        command: ["hyprctl", "-j", "monitors", "all"]

        stdout: StdioCollector {
            id: listOutput

            onStreamFinished: root.parse(listOutput.text)
        }
    }

    Timer {
        id: refreshTimer

        interval: 800
        onTriggered: root.refresh()
    }

    Timer {
        id: recoverTimer

        interval: 500
        onTriggered: {
            root.recovering = true;
            root.refresh();
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "monitoradded" || event.name === "monitoraddedv2"
                    || event.name === "monitorremoved" || event.name === "monitorremovedv2") {
                Quickshell.execDetached(["systemctl", "--user", "restart", "kanshi"]);
                refreshTimer.restart();
            }

            if (event.name === "monitorremoved" || event.name === "monitorremovedv2")
                recoverTimer.restart();
        }
    }

    Component.onCompleted: root.refresh()
}
