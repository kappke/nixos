pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components" as UI

PopupWindow {
    id: root

    property Item targetItem
    property var service
    property bool open: false
    signal closeRequested()

    visible: open
    grabFocus: true
    color: "transparent"
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 32

    anchor.item: root.targetItem
    anchor.rect.x: 0
    anchor.rect.y: root.targetItem ? root.targetItem.height + 4 : 0
    anchor.adjustment: PopupAdjustment.All

    onVisibleChanged: {
        if (!visible) {
            Qt.callLater(function() {
                if (!root.visible && root.open)
                    root.closeRequested();
            });
        } else {
            root.service.refresh();
        }
    }

    component Choice: Rectangle {
        id: choice

        property string label: ""
        property string icon: ""
        property bool selected: false
        property bool enabled: true
        signal clicked()

        height: 34
        radius: UI.Theme.controlRadius
        opacity: enabled ? 1 : 0.45
        color: selected ? UI.Theme.selected : area.containsMouse && enabled ? UI.Theme.hover : UI.Theme.raised
        border.width: selected ? 1 : 0
        border.color: UI.Theme.accent

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: choice.icon.length > 0
                text: choice.icon
                color: choice.selected ? UI.Theme.accentText : UI.Theme.secondaryText
                font.family: UI.Theme.iconFont
                font.pixelSize: 13
            }

            Text {
                text: choice.label
                color: choice.selected ? UI.Theme.accentText : UI.Theme.text
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            enabled: choice.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.clicked()
        }
    }

    UI.PopupFrame {
        anchors.fill: parent
        shown: root.open
        animationOrigin: Item.TopLeft

        Column {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12

            Row {
                width: parent.width
                height: 32

                Column {
                    spacing: 2

                    Text {
                        text: "Displays"
                        color: UI.Theme.text
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Text {
                        text: root.service.enabledMonitors.length + " of " + root.service.monitors.length + " active"
                        color: UI.Theme.mutedText
                        font.pixelSize: 10
                    }
                }

                Item {
                    width: parent.width - refreshButton.width - 90
                    height: 1
                }

                UI.IconButton {
                    id: refreshButton

                    icon: ""
                    onClicked: root.service.refresh()
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Choice {
                    width: (parent.width - 8) / 2
                    icon: ""
                    label: "Extend"
                    selected: root.service.layout === "extend"
                    enabled: root.service.monitors.length > 1
                    onClicked: root.service.extend()
                }

                Choice {
                    width: (parent.width - 8) / 2
                    icon: ""
                    label: "Mirror"
                    selected: root.service.layout === "mirror"
                    enabled: root.service.monitors.length > 1
                    onClicked: root.service.mirror()
                }
            }

            Column {
                width: parent.width
                spacing: 6
                visible: root.service.monitors.length > 1

                Text {
                    text: "Extend to the"
                    color: UI.Theme.mutedText
                    font.pixelSize: 10
                }

                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: ["left", "right", "above", "below"]

                        Choice {
                            required property string modelData

                            width: (parent.width - 18) / 4
                            height: 28
                            label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            selected: root.service.placement === modelData
                            onClicked: {
                                root.service.placement = modelData;
                                if (root.service.layout === "extend")
                                    root.service.extend();
                            }
                        }
                    }
                }
            }

            UI.Divider {
                width: parent.width
            }

            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.service.monitors

                    Rectangle {
                        id: card

                        required property var modelData

                        width: parent.width
                        height: 54
                        radius: UI.Theme.controlRadius
                        color: UI.Theme.raised
                        opacity: modelData.disabled ? 0.6 : 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: buttons.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: card.modelData.name + (card.modelData.internal ? "  (built-in)" : "")
                                color: UI.Theme.text
                                font.bold: true
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: card.modelData.disabled
                                    ? "Off"
                                    : card.modelData.width + "x" + card.modelData.height + " @ " + Math.round(card.modelData.refreshRate) + "Hz"
                                      + (card.modelData.mirrorOf !== "none" ? "  ·  mirrors " + card.modelData.mirrorOf : "")
                                color: UI.Theme.mutedText
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            id: buttons

                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Choice {
                                width: 56
                                height: 28
                                label: "Only"
                                enabled: root.service.monitors.length > 1
                                onClicked: root.service.only(card.modelData.name)
                            }

                            Choice {
                                width: 40
                                height: 28
                                icon: ""
                                selected: !card.modelData.disabled
                                enabled: card.modelData.disabled || root.service.enabledMonitors.length > 1
                                onClicked: root.service.toggle(card.modelData.name)
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.service.monitors.length === 0
                text: "No displays found"
                color: UI.Theme.subduedText
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
