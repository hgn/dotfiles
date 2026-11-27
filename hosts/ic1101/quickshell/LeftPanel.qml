import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// Left docked amethyst glass panel: numbered dark workspace circles with bright
// amethyst active pill + real active application icon, name and subtle title.
Panel {
    id: root
    dockLeft: true
    spacing: 8

    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    function dispatch(lua) { Hyprland.dispatch(lua) }

    function entryFor(cls) {
        if (!cls) return null
        const low = cls.toLowerCase()
        const apps = DesktopEntries.applications.values
        let hit = apps.find(e => e.id && e.id.toLowerCase() === low)
               || apps.find(e => e.startupClass && e.startupClass.toLowerCase() === low)
               || apps.find(e => e.name && e.name.toLowerCase() === low)
               || apps.find(e => e.id && e.id.toLowerCase().endsWith("." + low))
        return hit || null
    }

    function iconSrcFor(cls, entry) {
        const candidates = []
        if (entry && entry.icon) candidates.push(entry.icon)
        if (cls) {
            candidates.push(cls)
            candidates.push(cls.toLowerCase())
        }
        for (const c of candidates) {
            if (!c) continue
            if (c.startsWith("/")) return "file://" + c
            if (Quickshell.hasThemeIcon(c)) return Quickshell.iconPath(c)
        }
        return ""
    }

    function appDisplayName(cls, entry) {
        if (entry && entry.name) return entry.name
        if (!cls) return ""
        const base = cls.includes(".") ? cls.split(".").pop() : cls
        return base.charAt(0).toUpperCase() + base.slice(1)
    }

    // Workspaces: all 7 themed rooms always visible.
    Item {
        id: ws
        readonly property var list: Hyprland.workspaces.values
        readonly property int active: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
                                      ? Hyprland.focusedMonitor.activeWorkspace.id : 1
        readonly property int count: Math.max(7, active, ...list.map(w => w.id).filter(i => i > 0 && i <= 10))
        implicitWidth: wsRow.implicitWidth + 6
        implicitHeight: Theme.barHeight - 8
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 5

            Repeater {
                model: ws.count

                Rectangle {
                    id: btn
                    required property int index
                    readonly property int wid: index + 1
                    readonly property bool isActive: wid === ws.active
                    readonly property var info: ws.list.find(w => w.id === wid)
                    readonly property bool occupied: info !== undefined && info.toplevels.values.length > 0
                    readonly property bool isUrgent: info !== undefined && info.urgent

                    anchors.verticalCenter: parent.verticalCenter
                    width: isActive ? 42 : 26
                    height: 26
                    radius: 13
                    color: isActive ? Qt.rgba(0.05, 0.04, 0.10, 0.88)
                         : isUrgent ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25)
                         : wsMouse.containsMouse ? Qt.rgba(0.18, 0.16, 0.28, 0.92)
                         : occupied ? Qt.rgba(0.09, 0.08, 0.15, 0.86)
                         : Qt.rgba(0.06, 0.055, 0.11, 0.62)
                    border.width: 1
                    border.color: isActive ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.55)
                                : isUrgent ? Theme.red
                                : wsMouse.containsMouse ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)
                                : occupied ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.28)
                                : Qt.rgba(1, 1, 1, 0.06)

                    Behavior on width { SpringAnimation { spring: 4.5; damping: 0.34; epsilon: 0.3 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Bright amethyst inner pill for the active workspace
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2.5
                        radius: height / 2
                        visible: btn.isActive
                        color: "#c4a7f7"
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#cdb4fb" }
                            GradientStop { position: 1.0; color: Theme.purple }
                        }
                    }

                    Txt {
                        anchors.centerIn: parent
                        text: root.kanji[btn.index] || String(btn.wid)
                        font.family: Theme.font
                        size: btn.isActive ? 15 : 14
                        font.weight: btn.isActive ? Font.Bold : (btn.occupied ? Font.SemiBold : Font.Medium)
                        color: btn.isActive ? "#13111c"
                             : btn.isUrgent ? Theme.red
                             : wsMouse.containsMouse ? Theme.fgBright
                             : btn.occupied ? Qt.rgba(0.75, 0.79, 0.96, 0.80)
                             : Qt.rgba(0.45, 0.49, 0.66, 0.54)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dispatch("hl.dsp.focus({ workspace = " + btn.wid + " })")
                    }
                }
            }
        }

        WheelHandler {
            onWheel: e => root.dispatch("hl.dsp.focus({ workspace = \"" + (e.angleDelta.y > 0 ? "e-1" : "e+1") + "\" })")
        }
    }

    // Subtle divider between workspaces and active app
    Rectangle {
        readonly property var tl: Hyprland.activeToplevel
        readonly property bool hasApp: tl !== null && tl.workspace && tl.workspace.id === ws.active
        visible: hasApp
        width: 1
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.28)
    }

    // Active app: real theme icon + bright app name + subtle window title
    Row {
        id: activeApp
        readonly property var tl: Hyprland.activeToplevel
        readonly property bool here: tl !== null && tl.workspace && tl.workspace.id === ws.active
        readonly property string cls: here && tl.lastIpcObject && tl.lastIpcObject.class
                                      ? tl.lastIpcObject.class : ""
        readonly property var entry: here ? root.entryFor(cls) : null
        readonly property string iconSrc: here ? root.iconSrcFor(cls, entry) : ""
        readonly property string appName: here ? root.appDisplayName(cls, entry) : ""
        readonly property string rawTitle: here && tl.title ? tl.title : ""
        readonly property string subTitle: {
            if (!rawTitle) return ""
            if (!appName) return rawTitle
            if (rawTitle.toLowerCase() === appName.toLowerCase()) return ""
            return rawTitle
        }

        visible: here && (appName !== "" || rawTitle !== "")
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7
        rightPadding: 6

        Item {
            width: 19
            height: 19
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                id: appImg
                anchors.fill: parent
                source: activeApp.iconSrc
                asynchronous: true
                visible: activeApp.iconSrc !== "" && status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                code: 0xF05AF
                size: 16
                color: Theme.purple
                visible: !appImg.visible
            }
        }

        Txt {
            visible: activeApp.appName !== ""
            text: activeApp.appName
            color: Theme.fgBright
            size: Theme.fontSize - 1
            font.weight: Font.SemiBold
            anchors.verticalCenter: parent.verticalCenter
        }

        Txt {
            visible: activeApp.appName !== "" && activeApp.subTitle !== ""
            text: "·"
            color: Theme.dim
            size: Theme.fontSize - 1
            anchors.verticalCenter: parent.verticalCenter
        }

        Txt {
            visible: activeApp.subTitle !== ""
            text: activeApp.subTitle
            color: Qt.rgba(0.75, 0.79, 0.96, 0.68)
            size: Theme.fontSize - 2
            font.weight: Font.Normal
            width: Math.min(implicitWidth, 240)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
