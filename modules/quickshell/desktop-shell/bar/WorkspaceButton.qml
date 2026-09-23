import QtQuick
import Quickshell.Io
import "../components" as UI

Item {
    id: root

    property var workspace: null
    required property string workspaceName
    property var applications: []

    implicitWidth: label.implicitWidth + appIcons.width + 24
    width: implicitWidth
    height: 28

    Rectangle {
        anchors.fill: parent
        color: root.workspace && root.workspace.focused ? UI.Theme.accent : root.workspace && root.workspace.urgent ? UI.Theme.urgent : "transparent"

        Behavior on color {
            ColorAnimation { duration: UI.Theme.animationNormal }
        }
    }

    Text {
        id: label

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.workspaceName
        color: root.workspace && (root.workspace.focused || root.workspace.urgent) ? UI.Theme.accentForeground : UI.Theme.subduedText
        font.family: UI.Theme.textFont
        font.pixelSize: 14
        font.weight: 600

        Behavior on color {
            ColorAnimation { duration: UI.Theme.animationNormal }
        }
    }

    Row {
        id: appIcons

        anchors.left: label.right
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.applications

            delegate: Item {
                required property var modelData

                width: 16
                height: 16

                UI.ApplicationIcon {
                    anchors.fill: parent
                    application: modelData
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.workspace)
                root.workspace.activate();
            else
                activateProcess.exec(["swaymsg", "workspace", "number", root.workspaceName]);
        }
    }

    Process {
        id: activateProcess
    }
}
