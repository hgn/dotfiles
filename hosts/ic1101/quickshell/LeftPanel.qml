import QtQuick
import Quickshell
import Quickshell.Hyprland

// Left floating glass panel: Debian launcher, Kanji workspaces (一..十), window title.
Panel {
    id: root
    dockLeft: true
    spacing: 4

    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    function dispatch(lua) { Hyprland.dispatch(lua) }

    // Debian launcher icon
    Chip {
        padX: 10
        Icon { code: 0xE77D; size: Theme.fontSize + 3; color: parent.parent.hovered ? Theme.cyan : Theme.blue }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("pkill -x fuzzel || fuzzel")
            else Store.launcherOpen = !Store.launcherOpen
        }
    }

    // Kanji workspaces: 6 persistent, active becomes a blue -> purple gradient pill
    Item {
        id: ws
        readonly property var list: Hyprland.workspaces.values
        readonly property int active: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
                                      ? Hyprland.focusedMonitor.activeWorkspace.id : 1
        readonly property int count: Math.max(6, active, ...list.map(w => w.id).filter(i => i > 0 && i <= 10))
        implicitWidth: wsRow.implicitWidth + 4
        implicitHeight: Theme.barHeight - 8
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 2

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

                    width: isActive ? 42 : 30
                    height: Theme.barHeight - 10
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Theme.chipRadius
                    color: isUrgent ? Theme.red
                         : isActive ? Theme.blue
                         : wsMouse.containsMouse ? Theme.hl
                         : "transparent"
                    border.width: !isActive && wsMouse.containsMouse ? 1 : 0
                    border.color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)
                    gradient: isActive && !isUrgent ? activeGrad : null

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Gradient {
                        id: activeGrad
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.blue }
                        GradientStop { position: 1; color: Theme.purple }
                    }

                    Txt {
                        anchors.centerIn: parent
                        text: root.kanji[btn.index] || String(btn.wid)
                        size: Theme.fontSize
                        font.weight: btn.isActive ? Font.Bold : Font.Medium
                        color: (btn.isActive || btn.isUrgent) ? Theme.bgSolid
                             : wsMouse.containsMouse ? Theme.fg
                             : btn.occupied ? Theme.fg
                             : Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.72)
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

    Divider {}

    // Active window title
    Item {
        readonly property var tl: Hyprland.activeToplevel
        readonly property bool here: tl && tl.workspace && tl.workspace.id === ws.active
        readonly property string title: here && tl.title ? tl.title : ""
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Math.min(Math.max(titleTxt.implicitWidth + 14, 96), 280)
        implicitHeight: Theme.barHeight - 8

        Txt {
            id: titleTxt
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: parent.title !== "" ? parent.title : (Theme.ic(0xF108) + "  Desktop")
            color: parent.title !== "" ? Theme.fg : Theme.dim
            size: Theme.fontSize
        }
    }
}
