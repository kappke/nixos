pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../components" as UI

PopupWindow {
    id: root

    required property Item targetItem
    required property var service
    property bool open: false

    visible: root.open
    color: "transparent"
    implicitWidth: 210
    implicitHeight: content.implicitHeight + 20

    anchor.item: root.targetItem
    anchor.rect.x: (root.targetItem.width - root.width) / 2
    anchor.rect.y: root.targetItem.height + 4
    anchor.adjustment: PopupAdjustment.All

    function resetText(window) {
        if (!window || window.resetAt <= 0)
            return "Reset time unavailable";
        return "Resets " + Qt.formatDateTime(new Date(window.resetAt * 1000), "dd MMM, HH:mm");
    }

    UI.PopupFrame {
        anchors.fill: parent
        radius: UI.Theme.tooltipRadius
        shown: root.open

        Column {
            id: content

            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: "ChatGPT usage"
                    color: UI.Theme.text
                    font.family: UI.Theme.textFont
                    font.pixelSize: 12
                    font.weight: 600
                }

                Text {
                    width: parent.width - x
                    text: root.service && root.service.plan ? root.service.plan.toUpperCase() : ""
                    color: UI.Theme.accentText
                    horizontalAlignment: Text.AlignRight
                    font.family: UI.Theme.textFont
                    font.pixelSize: 10
                }
            }

            Repeater {
                model: root.service ? root.service.windows : []

                delegate: Column {
                    id: windowColumn

                    required property var modelData

                    width: root.width - 20
                    spacing: 1

                    Text {
                        text: windowColumn.modelData.label + ": " + Math.round(windowColumn.modelData.usedPercent) + "% used"
                        color: UI.Theme.text
                        font.family: UI.Theme.textFont
                        font.pixelSize: 11
                    }

                    Text {
                        text: root.resetText(windowColumn.modelData)
                        color: UI.Theme.mutedText
                        font.family: UI.Theme.textFont
                        font.pixelSize: 10
                    }
                }
            }

            Text {
                width: parent.width
                text: root.service && root.service.loading ? "Refreshing..." : root.service && root.service.error ? root.service.error : root.service && root.service.lastUpdated ? "Updated just now" : "Waiting for usage data"
                color: root.service && root.service.error ? UI.Theme.danger : UI.Theme.mutedText
                elide: Text.ElideRight
                font.family: UI.Theme.textFont
                font.pixelSize: 10
            }
        }
    }
}
