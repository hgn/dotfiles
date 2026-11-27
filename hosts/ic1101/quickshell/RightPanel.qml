import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray

// Right floating glass panel: unread mail, RAM/Temp telemetry, tray, clipboard,
// idle inhibitor, VPN, WLAN, BT, audio, backlight, power profile, battery, power menu.
Panel {
    id: root
    required property var barWindow
    dockRight: true
    spacing: 1

    // Unread mail indicator (live IMAP INBOX, fallback notmuch)
    Chip {
        id: mailChip
        visible: Store.mailUnread > 0
        padX: 8
        spacing: 6
        tooltip: Store.mailUnread + " ungelesene E-Mail" + (Store.mailUnread === 1 ? "" : "s") + " in INBOX\nLinksklick: aktualisieren · Rechtsklick: Drop-down-Terminal"
        Icon { code: 0xF01EE; size: Theme.fontSize + 1; color: Theme.purple }
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

    // Technical telemetry: RAM + Temp (click opens detailed SysPopup with CPU graph)
    Chip {
        id: sysChip
        padX: 8
        spacing: 7
        color: hovered || Store.sysOpen ? Theme.hl : "transparent"
        tooltip: "System  ·  CPU " + Math.round(Store.cpu * 100) + "%  ·  Load " + (Store.load || "–")
               + "\nRAM: " + Store.memUsed.toFixed(1) + " / " + Store.memTotal.toFixed(0) + " GiB  ·  Temp: " + Math.round(Store.temp) + " °C"

        Icon { code: 0xF035B; size: Theme.fontSize + 1; color: Store.memUsed / Store.memTotal > 0.8 ? Theme.orange : Theme.purple }
        Txt {
            text: Store.memUsed.toFixed(1) + "G"
            color: Store.memUsed / Store.memTotal > 0.8 ? Theme.orange : Theme.purple
        }
        Icon { code: 0xF050F; size: Theme.fontSize + 1; color: Store.temp > 85 ? Theme.red : Theme.yellow }
        Txt {
            text: Math.round(Store.temp) + "°"
            color: Store.temp > 85 ? Theme.red : Theme.yellow
        }

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
                padX: 5
                IconImage {
                    implicitSize: 16
                    source: trayChip.modelData.icon
                    asynchronous: true
                }
                QsMenuAnchor {
                    id: trayMenu
                    menu: trayChip.modelData.menu
                    anchor.item: trayChip
                    anchor.rect.y: trayChip.height + 10
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
        padX: 7
        color: hovered || Store.clipOpen ? Theme.hl : "transparent"
        tooltip: "Zwischenablage (cliphist)\nLinksklick: Verlauf · Rechtsklick / Super+C: Fuzzel-Suche"
        Icon {
            code: 0xF014C
            size: Theme.fontSize + 1
            color: Store.clipOpen ? Theme.purple : Theme.fg
        }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("cliphist list | fuzzel --dmenu --prompt '󰅌  Clipboard › ' | cliphist decode | wl-copy")
            else Store.clipOpen = !Store.clipOpen
        }
    }

    // Idle inhibitor
    Chip {
        padX: 7
        tooltip: Store.inhibitIdle
            ? "Wachmodus aktiv\nVerhindert Abdunkeln, Sperren & Standby · Klick: aus"
            : "Wachmodus aus\nKlick: Bildschirm & Sperrbildschirm wach halten"
        Icon {
            code: Store.inhibitIdle ? 0xF0176 : 0xF0FAA
            size: Theme.fontSize + 2
            color: Store.inhibitIdle ? Theme.yellow : Theme.dim
        }
        onClicked: Store.toggleIdleInhibit()
    }

    // VPN (WireGuard fritz-wg)
    Chip {
        padX: 7
        tooltip: Store.vpnActive
            ? "VPN (fritz-wg) verbunden\nKlick: Tunnel trennen"
            : "VPN (fritz-wg) getrennt\nKlick: über Fritzbox verbinden"
        Icon {
            code: 0xF0582
            size: Theme.fontSize + 2
            color: Store.vpnActive ? Theme.green : Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.75)
        }
        onClicked: Store.toggleVpn()
    }

    // Network / WLAN
    Chip {
        padX: 8
        tooltip: Store.netType === "wifi"
            ? ("WLAN: " + Store.netLabel + " (" + Store.wifiSignal + "%)" + (Store.netIp ? "\nIP: " + Store.netIp : "") + "\nLinksklick: WLAN-Menü · Rechtsklick: Einstellungen")
            : Store.netType === "ethernet"
              ? ("Ethernet: " + Store.netLabel + (Store.netIp ? "\nIP: " + Store.netIp : "") + "\nLinksklick: WLAN-Menü · Rechtsklick: Einstellungen")
              : "Netzwerk: offline\nLinksklick: WLAN-Menü · Rechtsklick: Einstellungen"
        Icon {
            code: Store.netType === "wifi" ? Store.wifiIcon(Store.wifiSignal)
                : Store.netType === "ethernet" ? 0xF0200
                : 0xF092D
            size: Theme.fontSize + 2
            color: Store.netType === "offline" ? Theme.red : Theme.cyan
        }
        Txt {
            text: Store.netLabel
            color: Store.netType === "offline" ? Theme.red : Theme.cyan
            width: Math.min(implicitWidth, 120)
        }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("nm-connection-editor")
            else Store.run(Store.home + "/.local/share/wm/bin/wm-wifi")
        }
    }

    // Bluetooth
    Chip {
        id: btChip
        padX: 7
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
            size: Theme.fontSize + 2
            color: btChip.on ? Theme.blue : Theme.dim
        }
        Txt {
            text: String(btChip.connected)
            visible: btChip.connected > 0
            color: Theme.blue
        }
        onClicked: m => {
            if (m.button === Qt.RightButton) Store.run("blueman-manager")
            else if (adapter) adapter.enabled = !adapter.enabled
        }
    }

    // Audio / PipeWire (left: Mixer, middle: mute, right: pavucontrol, scroll: ±5%)
    Chip {
        id: volChip
        padX: 8
        color: hovered || Store.mixerOpen ? Theme.hl : "transparent"
        tooltip: (Store.muted ? "Audio stumm" : "Lautstärke: " + Math.round(Store.volume * 100) + "%")
               + (Store.sink ? "\nAusgabe: " + Store.nodeName(Store.sink) : "")
               + "\nKlick: Mixer · Mittelklick: Stumm · Scroll: ±5%"
        Icon {
            code: Store.volumeIcon(Store.volume, Store.muted)
            size: Theme.fontSize + 2
            color: Store.muted ? Theme.dim : Theme.purple
        }
        Txt {
            text: Store.muted ? "stumm" : Math.round(Store.volume * 100) + "%"
            color: Store.muted ? Theme.dim : Theme.purple
            width: 52
            horizontalAlignment: Text.AlignRight
        }
        onClicked: m => {
            if (m.button === Qt.MiddleButton) Store.toggleMute()
            else if (m.button === Qt.RightButton) Store.run("pavucontrol")
            else Store.mixerOpen = !Store.mixerOpen
        }
        onWheel: w => Store.setVolume(Store.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
    }

    // Backlight (click: popup slider, scroll: ±5%)
    Chip {
        id: briChip
        visible: Store.brightnessAvailable
        padX: 8
        color: hovered || Store.briOpen ? Theme.hl : "transparent"
        tooltip: "Helligkeit: " + Math.round(Store.brightness * 100) + "%\nKlick: Regler · Scroll: ±5%"
        Icon {
            code: Store.brightnessIcon(Store.brightness)
            size: Theme.fontSize + 2
            color: Theme.yellow
        }
        Txt {
            text: Math.round(Store.brightness * 100) + "%"
            color: Theme.yellow
            width: 44
            horizontalAlignment: Text.AlignRight
        }
        onClicked: Store.briOpen = !Store.briOpen
        onWheel: w => Store.stepBrightness(w.angleDelta.y > 0 ? 0.05 : -0.05)
    }

    Divider {}

    // Power profile (click cycles power-saver -> balanced -> performance)
    Chip {
        padX: 7
        tooltip: "Energieprofil: " + Store.powerProfileLabel(Store.powerProfile) + "\n"
            + Store.powerProfileDesc(Store.powerProfile) + " · Klick: wechseln"
        Icon {
            code: Store.powerProfileIcon(Store.powerProfile)
            size: Theme.fontSize + 2
            color: Store.powerProfileColor(Store.powerProfile)
        }
        onClicked: Store.cyclePowerProfile()
    }

    // Battery (BAT0)
    Chip {
        id: batChip
        visible: Store.batPresent
        padX: 8
        readonly property bool charging: Store.batStatus === "Charging" || Store.batStatus === "Full"
        readonly property bool warn: !charging && Store.batPercent <= 25 && Store.batPercent > 10
        readonly property bool crit: !charging && Store.batPercent <= 10
        tooltip: "Akku: " + Store.batPercent + "% (" + (Store.batStatus === "Charging" ? "lädt" : Store.batStatus === "Discharging" ? "entlädt" : Store.batStatus) + ")"
               + (Store.batWatts > 0.1 ? ("\nLeistung: " + Store.batWatts.toFixed(1) + " W" + (Store.batTime ? "  ·  Restzeit: " + Store.batTime : "")) : "")
               + "\nKlick: System-Details"

        property real critPulse: 0
        SequentialAnimation on critPulse {
            running: batChip.crit
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 750; easing.type: Easing.InOutSine }
        }

        color: crit ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.35 + 0.55 * critPulse)
             : hovered ? Theme.hl : "transparent"

        Icon {
            code: Store.batteryIcon(Store.batPercent, Store.batStatus)
            size: Theme.fontSize + 2
            color: batChip.crit ? Theme.bgSolid
                 : batChip.charging ? Theme.cyan
                 : batChip.warn ? Theme.orange
                 : Theme.green
        }
        Txt {
            text: Store.batStatus === "Full" ? "voll" : (Store.batPercent + "%")
            color: batChip.crit ? Theme.bgSolid
                 : batChip.charging ? Theme.cyan
                 : batChip.warn ? Theme.orange
                 : Theme.green
        }
        onClicked: Store.sysOpen = !Store.sysOpen
    }

    // Power menu trigger
    Chip {
        padX: 9
        hoverColor: Theme.red
        tooltip: "Sitzungsmenü\nSperren · Standby · Abmelden · Neustart · Ausschalten"
        Icon {
            code: 0xF0425
            size: Theme.fontSize + 2
            color: parent.parent.hovered ? Theme.bgSolid : Theme.red
        }
        onClicked: Store.powerOpen = !Store.powerOpen
    }

    ClipboardPopup { anchorItem: clipChip; barWindow: root.barWindow }
    Mixer { anchorItem: volChip; barWindow: root.barWindow }
    BrightnessPopup { anchorItem: briChip; barWindow: root.barWindow }
    SysPopup { anchorItem: sysChip; barWindow: root.barWindow }
}
