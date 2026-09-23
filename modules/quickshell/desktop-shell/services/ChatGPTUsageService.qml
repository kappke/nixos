import QtQuick
import Quickshell.Io

Item {
    id: root

    property string plan: ""
    property var windows: []
    property string error: ""
    property bool loading: false
    property var lastUpdated: null

    readonly property var primaryWindow: windows.length > 0 ? windows[0] : null

    visible: false

    function refresh() {
        root.loading = true;
        root.error = "";
        usageProcess.exec(usageProcess.command);
    }

    function numberOr(value, fallback) {
        const number = Number(value);
        return isFinite(number) ? number : fallback;
    }

    function windowLabel(window, fallback) {
        const seconds = root.numberOr(window.limit_window_seconds, 0);
        if (seconds >= 5 * 24 * 60 * 60)
            return "7-day";
        if (seconds >= 3 * 60 * 60)
            return "5-hour";
        return fallback;
    }

    function parseWindow(window, fallback) {
        if (!window)
            return null;
        const usedPercent = root.numberOr(window.used_percent, -1);
        if (usedPercent < 0)
            return null;
        return {
            label: root.windowLabel(window, fallback),
            usedPercent: Math.max(0, Math.min(100, usedPercent)),
            resetAt: root.numberOr(window.reset_at, 0),
            resetAfterSeconds: root.numberOr(window.reset_after_seconds, 0),
            windowMinutes: Math.round(root.numberOr(window.limit_window_seconds, 0) / 60)
        };
    }

    function consume(output) {
        let payload;
        try {
            payload = JSON.parse(output);
        } catch (parseError) {
            root.windows = [];
            root.error = "ChatGPT returned invalid usage data";
            return;
        }

        const rateLimit = payload.rate_limit || {};
        const parsedWindows = [];
        const primary = root.parseWindow(rateLimit.primary_window, "Current");
        const secondary = root.parseWindow(rateLimit.secondary_window, "Longer window");
        if (primary)
            parsedWindows.push(primary);
        if (secondary)
            parsedWindows.push(secondary);

        root.windows = parsedWindows;
        root.plan = String(payload.plan_type || "").replace(/_/g, " ");
        root.lastUpdated = new Date();
        if (parsedWindows.length === 0)
            root.error = "No usage limits returned";
    }

    Process {
        id: usageProcess

        command: ["chatgpt-usage"]

        stdout: StdioCollector {
            id: usageOutput

            onStreamFinished: root.consume(usageOutput.text)
        }

        stderr: StdioCollector {
            id: usageError
        }

        onExited: function(exitCode) {
            root.loading = false;
            if (exitCode !== 0) {
                root.windows = [];
                root.error = usageError.text.trim() || "ChatGPT usage unavailable";
            }
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
