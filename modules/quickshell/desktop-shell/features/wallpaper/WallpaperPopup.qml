pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../components" as UI

PopupWindow {
    id: root

    property Item targetItem
    property string wallpaperDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string wallpaperStateFile: Quickshell.env("HOME") + "/.config/quickshell/wallpaper-state"
    property var wallpapers: []
    property string selectedPath: ""
    property bool open: false
    signal closeRequested()

    visible: open
    grabFocus: true
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 390

    anchor.item: root.targetItem
    anchor.rect.x: 0
    anchor.rect.y: root.targetItem ? root.targetItem.height + 4 : 0
    anchor.adjustment: PopupAdjustment.All

    function loadWallpapers() {
        wallpaperProcess.exec(["find", "-L", root.wallpaperDirectory, "-maxdepth", "1", "-type", "f", "-print"]);
    }

    function applyWallpaper(path) {
        if (!path)
            return;
        root.selectedPath = path;
        Quickshell.execDetached(["set-wallpaper", path, "--transition-type", "fade"]);
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "wallpaper-state", path, root.wallpaperStateFile]);
    }

    onVisibleChanged: {
        if (!visible) {
            Qt.callLater(function() {
                if (!root.visible && root.open)
                    root.closeRequested();
            });
        } else {
            root.loadWallpapers();
        }
    }

    Process {
        id: wallpaperProcess

        stdout: StdioCollector {
            id: wallpaperOutput

            onStreamFinished: {
                const lines = wallpaperOutput.text.trim().split("\n");
                const result = [];
                for (let i = 0; i < lines.length; ++i) {
                    const path = lines[i].trim();
                    if (path.length === 0)
                        continue;
                    if (/\.(png|jpe?g|webp|gif|mp4|mkv|webm|mov)$/i.test(path))
                        result.push(path);
                }
                result.sort();
                root.wallpapers = result;
            }
        }
    }

    FileView {
        id: wallpaperStateView

        path: root.wallpaperStateFile
        printErrors: false

        onLoaded: {
            const savedPath = wallpaperStateView.text().trim();
            if (savedPath.length > 0)
                root.selectedPath = savedPath;
        }
    }

    UI.PopupFrame {
        anchors.fill: parent
        shown: root.open
        animationOrigin: Item.TopLeft

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
                        text: "Wallpaper"
                        color: UI.Theme.text
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Text {
                        text: root.wallpaperDirectory
                        color: UI.Theme.mutedText
                        elide: Text.ElideMiddle
                        font.pixelSize: 10
                    }
                }

                Item {
                    width: parent.width - refreshButton.width - 8
                    height: 1
                }

                UI.IconButton {
                    id: refreshButton

                    icon: "\uf021"
                    onClicked: root.loadWallpapers()
                }
            }

            Item {
                width: parent.width
                height: 290

                ListView {
                    anchors.fill: parent
                    spacing: 5
                    clip: true
                    model: root.wallpapers

                    delegate: Rectangle {
                        required property string modelData

                        width: ListView.view ? ListView.view.width : 0
                        height: 42
                        radius: 7
                        color: modelData === root.selectedPath ? UI.Theme.selected : mouseArea.containsMouse ? UI.Theme.hover : UI.Theme.raised
                        border.width: modelData === root.selectedPath ? 1 : 0
                        border.color: UI.Theme.accent

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 30
                            radius: 5
                            color: UI.Theme.inset

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectCrop
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 64
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.substring(modelData.lastIndexOf("/") + 1)
                            color: UI.Theme.text
                            elide: Text.ElideMiddle
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyWallpaper(modelData)
                        }
                    }
                }

                UI.EmptyState {
                    anchors.centerIn: parent
                    visible: root.wallpapers.length === 0
                    text: "No wallpapers found"
                }
            }

            Text {
                width: parent.width
                text: "Add images to ~/Pictures/Wallpapers"
                color: UI.Theme.subduedText
                font.pixelSize: 10
            }
        }
    }
}
