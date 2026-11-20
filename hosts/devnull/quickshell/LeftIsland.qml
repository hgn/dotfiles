import QtQuick
import Quickshell
import Quickshell.Hyprland

DockedIsland {
    id: root
    spacing: 6

    function dispatch(lua) { Hyprland.dispatch(lua) }

    Chip {
        Icon { code: 0xE77D; size: 22; color: parent.parent.hovered ? Theme.cyan : Theme.blue }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("pkill -x fuzzel || fuzzel")
            else Store.launcherOpen = !Store.launcherOpen
        }
    }

    // workspaces as page-indicator dots; the active one stretches into a pill
    Item {
        id: ws
        readonly property var list: Hyprland.workspaces.values
        readonly property int active: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
                                      ? Hyprland.focusedMonitor.activeWorkspace.id : 1
        readonly property int count: Math.max(4, active, ...list.map(w => w.id).filter(i => i > 0 && i < 11))
        implicitWidth: dots.implicitWidth + 16
        implicitHeight: 38

        Row {
            id: dots
            anchors.centerIn: parent
            spacing: 8
            Repeater {
                model: ws.count
                Rectangle {
                    id: dot
                    required property int index
                    readonly property int wid: index + 1
                    readonly property bool isActive: wid === ws.active
                    readonly property var info: ws.list.find(w => w.id === wid)
                    readonly property bool occupied: info !== undefined && info.toplevels.values.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: isActive ? 40 : 13
                    height: 13
                    radius: 6.5
                    color: isActive ? Theme.blue : occupied ? Qt.rgba(0.75, 0.79, 0.96, dotMouse.containsMouse ? 0.9 : 0.6)
                                                            : (dotMouse.containsMouse ? Theme.hl : "transparent")
                    border.width: isActive || occupied ? 0 : 2
                    border.color: Theme.dim
                    gradient: isActive ? activeGrad : null
                    Behavior on width { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.3 } }
                    Gradient {
                        id: activeGrad
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.blue }
                        GradientStop { position: 1; color: Theme.purple }
                    }
                    MouseArea {
                        id: dotMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dispatch("hl.dsp.focus({ workspace = " + dot.wid + " })")
                    }
                }
            }
        }
        WheelHandler {
            onWheel: e => root.dispatch("hl.dsp.focus({ workspace = \"" + (e.angleDelta.y > 0 ? "e-1" : "e+1") + "\" })")
        }
    }

    Txt {
        readonly property var tl: Hyprland.activeToplevel
        readonly property bool here: tl && tl.workspace && tl.workspace.id === ws.active
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 620)
        rightPadding: 12
        text: here ? tl.title : ""
        visible: text !== ""
        color: Qt.rgba(0.75, 0.79, 0.96, 0.8)
        size: Theme.fontSize + 2
    }
}
