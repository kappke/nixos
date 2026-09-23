pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components" as UI

PanelWindow {
    id: root

    property var applications: ({})
    property string outputName: ""
    readonly property bool revealed: dockMouseArea.containsMouse || dockFrameHoverHandler.hovered
    readonly property var openApplications: applicationsForOutput()
    readonly property int dockHeight: 82
    readonly property int revealHeight: 6
    readonly property int dockBottomMargin: 10

    anchors {
        bottom: true
        left: true
        right: true
    }
    visible: true
    implicitHeight: root.revealed ? root.dockHeight : root.revealHeight
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    Behavior on implicitHeight {
        NumberAnimation {
            duration: UI.Theme.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    function applicationsForOutput() {
        const result = [];
        const workspaces = root.applications || {};
        const workspaceNames = Object.keys(workspaces);

        for (let i = 0; i < workspaceNames.length; ++i) {
            const workspaceApplications = workspaces[workspaceNames[i]] || [];
            for (let j = 0; j < workspaceApplications.length; ++j) {
                const application = workspaceApplications[j];
                if (!application)
                    continue;
                if (root.outputName && application.output !== root.outputName)
                    continue;
                result.push(application);
            }
        }

        return result;
    }

    function applicationLabel(application) {
        if (!application)
            return "Application";
        return String(application.appId || application.className || application.title || "Application");
    }

    function activateApplication(application) {
        if (!application)
            return;

        if (application.id)
            Quickshell.execDetached(["swaymsg", "[con_id=" + application.id + "] focus"]);
        else if (application.workspaceName)
            Quickshell.execDetached(["swaymsg", "workspace", "number", application.workspaceName]);
    }

    MouseArea {
        id: dockMouseArea

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }

    Rectangle {
        id: dockFrame

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.dockBottomMargin
        width: Math.min(Math.max(root.openApplications.length * 64 + 16, root.openApplications.length > 0 ? 80 : 112), Math.max(0, root.width - 24))
        height: root.dockHeight - root.dockBottomMargin
        radius: 14
        color: UI.Theme.surface
        border.width: 1
        border.color: UI.Theme.border
        opacity: root.revealed ? 1 : 0
        scale: root.revealed ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: UI.Theme.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: UI.Theme.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: dockFrameHoverHandler
        }

        ListView {
            id: appList

            anchors.fill: parent
            anchors.margins: 8
            orientation: ListView.Horizontal
            spacing: 4
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            model: root.openApplications

            delegate: Item {
                id: appDelegate

                required property var modelData

                width: 64
                height: appList.height

                Rectangle {
                    anchors.fill: parent
                    radius: UI.Theme.controlRadius
                    color: appMouseArea.containsMouse ? UI.Theme.strongHover : appDelegate.modelData && appDelegate.modelData.focused ? UI.Theme.selected : "transparent"
                    border.width: appDelegate.modelData && appDelegate.modelData.focused ? 1 : 0
                    border.color: UI.Theme.accent
                }

                UI.ApplicationIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    width: 36
                    height: 36
                    application: appDelegate.modelData
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text: root.applicationLabel(appDelegate.modelData)
                    color: appDelegate.modelData && appDelegate.modelData.focused ? UI.Theme.accentText : UI.Theme.secondaryText
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.family: UI.Theme.textFont
                    font.pixelSize: 9
                }

                MouseArea {
                    id: appMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            root.activateApplication(appDelegate.modelData);
                    }
                }
            }
        }

        UI.EmptyState {
            anchors.centerIn: parent
            visible: root.openApplications.length === 0
            text: "No open apps"
        }
    }
}
