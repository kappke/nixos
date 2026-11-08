pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components" as UI

PanelWindow {
    id: root

    property Item targetItem
    property var service
    property bool open: false
    property bool copied: false
    signal closeRequested()

    visible: open
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function copyUrl(url) {
        Quickshell.execDetached(["wl-copy", url]);
        root.copied = true;
        copiedTimer.restart();
    }

    function statusText() {
        if (root.copied)
            return "Copied GIF URL to the clipboard";
        if (!root.service || root.service.query.trim().length === 0)
            return "Type to search Giphy without an API key";
        if (root.service.searching)
            return "Searching Giphy...";
        if (root.service.error.length > 0)
            return root.service.error;
        return root.service.results.length + " GIFs found";
    }

    onVisibleChanged: {
        if (!visible) {
            Qt.callLater(function() {
                if (!root.visible && root.open)
                    root.closeRequested();
            });
        } else {
            Qt.callLater(function() {
                searchInput.forceActiveFocus();
            });
        }
    }

    onBackingWindowVisibleChanged: {
        if (backingWindowVisible && root.open)
            Qt.callLater(function() {
                searchInput.forceActiveFocus();
            });
    }

    Timer {
        id: copiedTimer

        interval: 1800
        onTriggered: root.copied = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    UI.PopupFrame {
        id: popupFrame

        width: Math.min(560, root.width - 16)
        height: Math.min(570, root.height - 40)
        x: {
            const targetX = root.targetItem ? root.targetItem.mapToItem(null, 0, 0).x : 8;
            return Math.max(8, Math.min(root.width - width - 8, targetX));
        }
        y: root.targetItem ? root.targetItem.mapToItem(null, 0, root.targetItem.height).y + 4 : 32
        shown: root.open
        animationOrigin: Item.TopLeft

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Row {
                width: parent.width
                height: 32

                Column {
                    spacing: 2

                    Text {
                        text: "GIF search"
                        color: UI.Theme.text
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Text {
                        text: "Powered by Giphy web results"
                        color: UI.Theme.mutedText
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: UI.Theme.controlRadius
                color: UI.Theme.inset
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: UI.Theme.accent

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text.length === 0
                    text: "Search GIFs..."
                    color: UI.Theme.subduedText
                    font.family: UI.Theme.textFont
                    font.pixelSize: 13
                }

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.service ? root.service.query : ""
                    color: UI.Theme.text
                    selectionColor: UI.Theme.accent
                    selectedTextColor: UI.Theme.accentForeground
                    font.family: UI.Theme.textFont
                    font.pixelSize: 13
                    selectByMouse: true
                    focus: root.open

                    onTextChanged: if (root.service) root.service.scheduleSearch(text)
                    Keys.onReturnPressed: if (root.service) root.service.searchNow()
                    Keys.onEnterPressed: if (root.service) root.service.searchNow()
                    Keys.onEscapePressed: root.closeRequested()
                }
            }

            Item {
                width: parent.width
                height: parent.height - 126

                GridView {
                    id: resultsGrid

                    anchors.fill: parent
                    clip: true
                    cellWidth: width / 3
                    cellHeight: 134
                    model: root.service ? root.service.results : []

                    delegate: Item {
                        id: resultCell

                        required property var modelData

                        width: resultsGrid.cellWidth
                        height: resultsGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 8
                            radius: 8
                            color: resultMouse.containsMouse ? UI.Theme.hover : UI.Theme.raised
                            border.width: resultMouse.containsMouse ? 1 : 0
                            border.color: UI.Theme.accent
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                source: resultCell.modelData.preview
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                                playing: root.open
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 30
                                color: "#bb0a0a0a"

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: resultCell.modelData.title
                                    color: UI.Theme.text
                                    elide: Text.ElideRight
                                    font.family: UI.Theme.textFont
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: resultMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.copyUrl(resultCell.modelData.url)
                            }
                        }
                    }
                }

                UI.EmptyState {
                    anchors.centerIn: parent
                    visible: root.service && !root.service.searching && root.service.results.length === 0
                    text: root.service && root.service.query.trim().length > 0 ? "No GIFs found" : "Search for a reaction, mood, or moment"
                }
            }

            Text {
                width: parent.width
                text: root.statusText()
                color: root.service && root.service.error.length > 0 ? UI.Theme.danger : root.copied ? UI.Theme.accentText : UI.Theme.mutedText
                elide: Text.ElideRight
                font.pixelSize: 10
            }
        }
    }
}
