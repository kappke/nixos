import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property var application: null

    function iconSource() {
        const app = root.application || {};
        const appId = app.appId ? String(app.appId) : "";
        const className = app.className ? String(app.className) : "";
        const appIdLower = appId.toLowerCase();
        const classNameLower = className.toLowerCase();

        function themed(name) {
            return name && Quickshell.hasThemeIcon(name) ? Quickshell.iconPath(name) : "";
        }

        return themed(appId)
            || themed(appIdLower)
            || themed(className)
            || themed(classNameLower)
            || "";
    }

    function fallbackLabel() {
        const app = root.application || {};
        const name = app.appId || app.className || app.title || "";
        return name ? String(name).substring(0, 1).toUpperCase() : "?";
    }

    IconImage {
        id: iconImage

        anchors.fill: parent
        asynchronous: true
        source: root.iconSource()
    }

    Text {
        anchors.centerIn: parent
        visible: iconImage.source.length === 0
        text: root.fallbackLabel()
        color: Theme.mutedText
        font.family: Theme.textFont
        font.pixelSize: Math.max(9, Math.round(parent.width * 0.42))
        font.bold: true
    }
}
