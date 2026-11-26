import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray

DockedIsland {
    id: root
    spacing: 4
    required property var barWindow

    // Unread mail indicator (IMAP INBOX, fallback notmuch); click toggles scratchpad or refreshes
    Chip {
        id: mailChip
        visible: Store.mailUnread > 0
        padX: 10
        spacing: 7
        tooltip: Store.mailUnread + " ungelesene E-Mail" + (Store.mailUnread === 1 ? "" : "s") + " in INBOX\nLinksklick: aktualisieren · Rechtsklick: Drop-down-Terminal"
        Icon { code: 0xF01EE; size: 19; color: Theme.purple }
        Txt {
            text: String(Store.mailUnread)
            color: Theme.fgBright
            font.weight: Font.SemiBold
        }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"term\")'")
            else Store.refreshMail()
        }
    }

    Divider { visible: mailChip.visible }

    // System telemetry: Temp + RAM (CPU sparkline removed for a calmer bar; click opens full SysPopup)
    Chip {
        id: sysChip
        padX: 10
        spacing: 8
        color: hovered || Store.sysOpen ? Theme.hl : "transparent"
        tooltip: "System  ·  CPU " + Math.round(Store.cpu * 100) + "%  ·  Load " + (Store.load || "–")
               + "\nRAM: " + Store.memUsed.toFixed(1) + " / " + Store.memTotal.toFixed(0) + " GiB  ·  Temp: " + Math.round(Store.temp) + " °C"
        Icon { code: 0xF050F; size: 18; color: Store.temp > 85 ? Theme.red : Theme.yellow }
        Txt { text: Math.round(Store.temp) + "°"; color: Store.temp > 85 ? Theme.red : Theme.yellow }
        Icon { code: 0xF035B; size: 18; color: Theme.purple }
        Txt { text: Store.memUsed.toFixed(1) + "G"; color: Theme.purple }
        onClicked: Store.sysOpen = !Store.sysOpen
    }

    Divider {}

    // System tray
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        visible: trayRep.count > 0
        Repeater {
            id: trayRep
            model: SystemTray.items
            Chip {
                id: trayChip
                required property var modelData
                padX: 7
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

    // Clipboard history popup (left: popup, right: fuzzel picker)
    Chip {
        id: clipChip
        padX: 9
        color: hovered || Store.clipOpen ? Theme.hl : "transparent"
        tooltip: "Zwischenablage (cliphist)\nLinksklick: Verlauf · Rechtsklick / Super+C: Fuzzel-Suche"
        Icon {
            code: 0xF014C
            size: 19
            color: Store.clipOpen ? Theme.purple : Theme.fg
        }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("cliphist list | fuzzel --dmenu --prompt '󰅌  Clipboard › ' | cliphist decode | wl-copy")
            else Store.clipOpen = !Store.clipOpen
        }
    }

    // Network
    Chip {
        id: netChip
        padX: 9
        readonly property bool online: Networking.devices.values.some(d => d.connected)
        tooltip: online
            ? ("Netzwerk: " + (Store.netName || "verbunden") + (Store.netIp ? "\nIP: " + Store.netIp : "") + "\nKlick: Netzwerk-Einstellungen")
            : "Netzwerk: offline\nKlick: Netzwerk-Einstellungen"
        Icon { code: netChip.online ? 0xF0200 : 0xF0319; color: netChip.online ? Theme.cyan : Theme.red }
        onClicked: Store.run("nm-connection-editor")
    }

    // Bluetooth
    Chip {
        id: btChip
        padX: 9
        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property bool on: adapter !== null && adapter.enabled
        readonly property var connectedDevs: Bluetooth.devices.values.filter(d => d.connected)
        readonly property int connected: connectedDevs.length
        tooltip: !on
            ? "Bluetooth aus\nLinksklick: einschalten · Rechtsklick: Manager"
            : connected > 0
              ? ("Bluetooth verbunden (" + connected + ")\n" + connectedDevs.map(d => d.name || d.address).join(", ") + "\nLinksklick: aus · Rechtsklick: Manager")
              : "Bluetooth aktiv (keine Geräte)\nLinksklick: aus · Rechtsklick: Manager"
        Icon {
            code: !btChip.on ? 0xF00B2 : btChip.connected > 0 ? 0xF00B1 : 0xF00AF
            color: btChip.on ? Theme.blue : Theme.dim
        }
        Txt { text: String(btChip.connected); visible: btChip.connected > 0; color: Theme.blue }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("blueman-manager")
            else if (adapter) adapter.enabled = !adapter.enabled
        }
    }

    // Volume: click opens mixer, scroll ±2 %, middle click mutes
    Chip {
        id: volChip
        padX: 10
        color: hovered || Store.mixerOpen ? Theme.hl : "transparent"
        tooltip: (Store.muted ? "Audio stumm" : "Lautstärke: " + Math.round(Store.volume * 100) + "%")
               + (Store.sink ? "\nAusgabe: " + Store.nodeName(Store.sink) : "")
               + "\nKlick: Mixer · Mittelklick: Stumm · Scroll: ±2%"
        Icon {
            code: Store.volumeIcon(Store.volume, Store.muted)
            color: Store.muted ? Theme.dim : Theme.purple
        }
        Txt {
            text: Store.muted ? "stumm" : Math.round(Store.volume * 100) + "%"
            color: Store.muted ? Theme.dim : Theme.purple
            width: 54
            horizontalAlignment: Text.AlignRight
        }
        onClicked: m => {
            if (m.button === Qt.MiddleButton) Store.toggleMute()
            else Store.mixerOpen = !Store.mixerOpen
        }
        onWheel: w => Store.setVolume(Store.volume + (w.angleDelta.y > 0 ? 0.02 : -0.02))
    }

    // Idle inhibitor
    Chip {
        padX: 9
        tooltip: Store.inhibitIdle
            ? "Wachmodus aktiv\nVerhindert Sperrbildschirm & Monitor-Abschaltung · Klick: aus"
            : "Wachmodus aus\nKlick: Bildschirm wach halten"
        Icon {
            code: Store.inhibitIdle ? 0xF0176 : 0xF0FAA
            color: Store.inhibitIdle ? Theme.yellow : Theme.dim
        }
        onClicked: Store.inhibitIdle = !Store.inhibitIdle
    }

    // Power menu
    Chip {
        padX: 10
        hoverColor: Qt.rgba(0.97, 0.46, 0.56, 0.22)
        tooltip: "Sitzungsmenü\nSperren · Standby · Abmelden · Neustart · Ausschalten"
        Icon { code: 0xF0425; color: Theme.red }
        onClicked: Store.run(Store.home + "/.local/share/wm/bin/wm-power")
    }

    ClipboardPopup { anchorItem: clipChip; barWindow: root.barWindow }
    Mixer { anchorItem: volChip; barWindow: root.barWindow }
    SysPopup { anchorItem: sysChip; barWindow: root.barWindow }
}
