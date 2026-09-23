import QtQuick
import "../components" as UI

Item {
    id: root

    required property var service
    property bool hovered: mouseArea.containsMouse

    width: usageText.implicitWidth + 16
    height: 28

    Rectangle {
        anchors.fill: parent
        radius: UI.Theme.controlRadius
        color: mouseArea.pressed ? UI.Theme.accent : mouseArea.containsMouse ? UI.Theme.strongHover : "transparent"
        scale: mouseArea.pressed ? 0.96 : 1

        Behavior on color {
            ColorAnimation { duration: UI.Theme.animationFast }
        }

        Behavior on scale {
            NumberAnimation {
                duration: UI.Theme.animationFast
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: usageText

            anchors.centerIn: parent
            text: root.service && root.service.primaryWindow ? "GPT " + Math.round(root.service.primaryWindow.usedPercent) + "%" : "GPT --"
            color: {
                if (!root.service || root.service.loading)
                    return UI.Theme.mutedText;
                if (root.service.error.length > 0)
                    return UI.Theme.danger;
                if (root.service.primaryWindow && root.service.primaryWindow.usedPercent >= 90)
                    return UI.Theme.danger;
                if (root.service.primaryWindow && root.service.primaryWindow.usedPercent >= 70)
                    return UI.Theme.warning;
                return UI.Theme.text;
            }
            font.family: UI.Theme.textFont
            font.pixelSize: 12
            font.weight: 600
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.service.refresh()
        }
    }
}
