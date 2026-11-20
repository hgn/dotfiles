import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray

DockedIsland {
    id: root
    spacing: 2
    required property var barWindow

    // CPU sparkline, temperature, memory: opens the system popup
    Chip {
        id: sysChip
        spacing: 10
        color: hovered || Store.sysOpen ? Theme.hl : "transparent"
        Spark {
            width: 64; height: 24
            anchors.verticalCenter: parent.verticalCenter
            values: Store.cpuHistory
            stroke: Store.cpu > 0.75 ? Theme.red : Theme.blue
        }
        Txt { text: Math.round(Store.cpu * 100) + "%"; width: 46; color: Theme.blue }
        Icon { code: 0xF050F; size: 18; color: Store.temp > 85 ? Theme.red : Theme.yellow }
        Txt { text: Math.round(Store.temp) + "°"; color: Store.temp > 85 ? Theme.red : Theme.yellow }
        Icon { code: 0xF035B; size: 18; color: Theme.purple }
        Txt { text: Store.memUsed.toFixed(1) + "G"; color: Theme.purple }
        onClicked: Store.sysOpen = !Store.sysOpen
    }

    // system tray
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        leftPadding: 6
        rightPadding: 6
        Repeater {
            model: SystemTray.items
            Chip {
                id: trayChip
                required property var modelData
                implicitWidth: 38
                IconImage {
                    implicitSize: 20
                    source: trayChip.modelData.icon
                    asynchronous: true
                }
                QsMenuAnchor {
                    id: trayMenu
                    menu: trayChip.modelData.menu
                    anchor.item: trayChip
                    anchor.rect.y: trayChip.height + 14
                    anchor.edges: Edges.Top
                    anchor.gravity: Edges.Bottom
                }
                onClicked: m => {
                    if (m.button === Qt.RightButton || (m.button === Qt.LeftButton && modelData.onlyMenu)) {
                        if (modelData.hasMenu) trayMenu.open()
                    } else if (m.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    } else {
                        modelData.activate()
                    }
                }
                onWheel: w => modelData.scroll(w.angleDelta.y, false)
            }
        }
    }

    Chip {
        readonly property bool online: Networking.devices.values.some(d => d.connected)
        Icon { code: parent.parent.online ? 0xF0200 : 0xF0319; color: parent.parent.online ? Theme.cyan : Theme.red }
        onClicked: Store.run("nm-connection-editor")
    }

    Chip {
        id: btChip
        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property bool on: adapter !== null && adapter.enabled
        readonly property int connected: Bluetooth.devices.values.filter(d => d.connected).length
        Icon {
            code: !btChip.on ? 0xF00B2 : btChip.connected > 0 ? 0xF00B1 : 0xF00AF
            color: btChip.on ? Theme.blue : Theme.dim
        }
        Txt { text: btChip.connected; visible: btChip.connected > 0; color: Theme.blue }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("blueman-manager")
            else if (adapter) adapter.enabled = !adapter.enabled
        }
    }

    // volume: click opens the mixer, scroll ±2 %, middle click mutes
    Chip {
        id: volChip
        color: hovered || Store.mixerOpen ? Theme.hl : "transparent"
        Icon {
            code: Store.volumeIcon(Store.volume, Store.muted)
            color: Store.muted ? Theme.dim : Theme.purple
        }
        Txt {
            text: Store.muted ? "stumm" : Math.round(Store.volume * 100) + "%"
            color: Store.muted ? Theme.dim : Theme.purple
            width: 58
        }
        onClicked: m => {
            if (m.button === Qt.MiddleButton) Store.toggleMute()
            else Store.mixerOpen = !Store.mixerOpen
        }
        onWheel: w => Store.setVolume(Store.volume + (w.angleDelta.y > 0 ? 0.02 : -0.02))
    }

    Chip {
        Icon {
            code: Store.inhibitIdle ? 0xF0176 : 0xF0FAA
            color: Store.inhibitIdle ? Theme.yellow : Theme.dim
        }
        onClicked: Store.inhibitIdle = !Store.inhibitIdle
    }

    Chip {
        hoverColor: Qt.rgba(0.97, 0.46, 0.56, 0.22)
        Icon { code: 0xF0425; color: Theme.red }
        onClicked: Store.run(Store.home + "/.local/share/wm/bin/wm-power")
    }

    Mixer { anchorItem: volChip; barWindow: root.barWindow }
    SysPopup { anchorItem: sysChip; barWindow: root.barWindow }
}
