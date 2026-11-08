import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property var applications: ({})
    // Hyprland only: name of the focused workspace, refreshed together with the clients.
    property string focusedWorkspace: ""
    readonly property bool isHyprland: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""

    // Same shape as the Sway workspace objects used by the bar.
    function hyprlandWorkspace(name) {
        return {
            focused: root.focusedWorkspace === name,
            urgent: false,
            activate: function() {
                Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + name + " })"]);
            }
        };
    }

    function updateHyprland(output) {
        if (!output || output.trim().length === 0)
            return;

        try {
            const state = JSON.parse(output);
            const monitorNames = ({});
            let focusedName = "";
            for (const monitor of state.monitors) {
                monitorNames[monitor.id] = monitor.name;
                if (monitor.focused)
                    focusedName = String(monitor.activeWorkspace.name);
            }

            const next = ({});
            for (const client of state.clients) {
                if (!client.mapped || client.hidden || !client.class)
                    continue;

                const workspaceName = String(client.workspace.name);
                if (!next[workspaceName])
                    next[workspaceName] = [];
                next[workspaceName].push({
                    key: client.address,
                    id: 0,
                    address: client.address,
                    appId: client.class,
                    className: client.class,
                    title: client.title || "",
                    workspaceName: workspaceName,
                    output: monitorNames[client.monitor] || "",
                    focused: false
                });
            }

            root.focusedWorkspace = focusedName;
            root.applications = next;
        } catch (error) {
            // hyprctl can fail while the compositor reloads; keep the last valid model.
        }
    }

    function update(output) {
        if (!output || output.trim().length === 0)
            return;

        try {
            const tree = JSON.parse(output);
            const next = ({});

            function walk(node, workspaceName, outputName) {
                if (!node)
                    return;

                let currentWorkspace = workspaceName;
                let currentOutput = outputName;
                if (node.type === "workspace") {
                    currentWorkspace = node.name || workspaceName;
                    currentOutput = node.output || outputName;
                    if (currentWorkspace && !next[currentWorkspace])
                        next[currentWorkspace] = [];
                }

                const nodes = (node.nodes || []).concat(node.floating_nodes || []);
                const properties = node.window_properties || {};
                const appId = node.app_id || "";
                const className = properties.class || properties.instance || "";

                if (currentWorkspace && node.type === "con" && (appId || className) && (nodes.length === 0 || node.pid)) {
                    const key = String(node.id || appId || className);
                    const existing = next[currentWorkspace];
                    let duplicate = false;
                    for (let i = 0; i < existing.length; ++i) {
                        if (existing[i].key === key) {
                            duplicate = true;
                            break;
                        }
                    }
                    if (!duplicate)
                        existing.push({
                            key: key,
                            id: node.id || 0,
                            appId: appId,
                            className: className,
                            title: node.name || "",
                            workspaceName: currentWorkspace,
                            output: currentOutput || "",
                            focused: !!node.focused
                        });
                }

                for (let i = 0; i < nodes.length; ++i)
                    walk(nodes[i], currentWorkspace, currentOutput);
            }

            walk(tree, "", "");
            root.applications = next;
        } catch (error) {
            // Sway may return a partial tree while reloading; keep the last valid model.
        }
    }

    visible: false

    Process {
        id: treeProcess

        command: ["swaymsg", "-t", "get_tree", "-r"]

        stdout: StdioCollector {
            id: treeOutput

            onStreamFinished: root.update(treeOutput.text)
        }
    }

    Process {
        id: hyprlandProcess

        command: ["sh", "-c", "printf '{\"monitors\":'; hyprctl -j monitors; printf ',\"clients\":'; hyprctl -j clients; printf '}'"]

        stdout: StdioCollector {
            id: hyprlandOutput

            onStreamFinished: root.updateHyprland(hyprlandOutput.text)
        }
    }

    function refresh() {
        if (root.isHyprland)
            hyprlandProcess.exec(hyprlandProcess.command);
        else
            treeProcess.exec(treeProcess.command);
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: eventRefresh

        interval: 50
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.isHyprland

        function onRawEvent(event) {
            switch (event.name) {
            case "workspacev2":
            case "focusedmonv2":
            case "openwindow":
            case "closewindow":
            case "movewindowv2":
            case "windowtitlev2":
                eventRefresh.restart();
            }
        }
    }
}
