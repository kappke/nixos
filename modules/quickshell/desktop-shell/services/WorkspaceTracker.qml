import QtQuick
import Quickshell.Io

Item {
    id: root

    property var applications: ({})

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

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: treeProcess.exec(treeProcess.command)
    }
}
