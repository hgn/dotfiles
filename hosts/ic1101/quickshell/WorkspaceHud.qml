import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Subtle bottom-center glass pill HUD that briefly announces the workspace room
// (1 Ink · 2 Rose · 3 Synth · 4 Zen · 5 Glass · 6 Phosphor · 7 Brutal) on switch.
Scope {
    id: hud

    property bool shown: false
    property bool visiblePhase: false
    property int lastWs: -1
    property int currentWs: 1

    readonly property var rooms: ({
        1: { name: "INK",      accent: "#7aa2f7", sub: "Scrolling · ruhig" },
        2: { name: "ROSE",     accent: "#ea9a97", sub: "Scrolling · Rosé Pine" },
        3: { name: "SYNTH",    accent: "#ff7edb", sub: "Scrolling · Synthwave" },
        4: { name: "ZEN",      accent: "#bb9af7", sub: "Monocle · randlos" },
        5: { name: "GLASS",    accent: "#7dcfff", sub: "Scrolling · Vollbild" },
        6: { name: "PHOSPHOR", accent: "#33ff66", sub: "Scrolling · CRT" },
        7: { name: "BRUTAL",   accent: "#d79921", sub: "Scrolling · Gruvbox" }
    })

    readonly property var room: rooms[currentWs] || {
        name: "WORKSPACE " + currentWs,
        accent: "#bb9af7",
        sub: "Scrolling"
    }

    function trigger(wsId) {
        if (wsId <= 0) return
        if (lastWs < 0) { lastWs = wsId; currentWs = wsId; return }
        if (wsId === lastWs) return
        lastWs = wsId
        currentWs = wsId
        hideTimer.stop()
        unloadTimer.stop()
        shown = true
        visiblePhase = true
        hideTimer.restart()
    }

    Connections {
        target: Hyprland.focusedMonitor
        ignoreUnknownSignals: true
        function onActiveWorkspaceChanged() {
            const ws = Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
                       ? Hyprland.focusedMonitor.activeWorkspace.id : -1
            hud.trigger(ws)
        }
    }

    Component.onCompleted: {
        const ws = Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
                   ? Hyprland.focusedMonitor.activeWorkspace.id : 1
        hud.lastWs = ws
        hud.currentWs = ws
    }

    Timer {
        id: hideTimer
        interval: 900
        onTriggered: {
            hud.visiblePhase = false
            unloadTimer.restart()
        }
    }

    Timer {
        id: unloadTimer
        interval: 260
        onTriggered: if (!hud.visiblePhase) hud.shown = false
    }

    LazyLoader {
        active: hud.shown

        PanelWindow {
            id: win

            screen: {
                const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
                return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
            }
            anchors { bottom: true }
            margins.bottom: 34
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: pill.implicitWidth + 20
            implicitHeight: pill.implicitHeight + 20
            color: "transparent"
            WlrLayershell.namespace: "qs-ws-hud"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                id: pill
                anchors.centerIn: parent
                implicitWidth: row.implicitWidth + 36
                implicitHeight: 46
                radius: 23
                color: Qt.rgba(0.085, 0.075, 0.145, 0.72)
                border.width: 1.2
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.62)

                readonly property color accentColor: hud.room.accent

                opacity: hud.visiblePhase ? 1 : 0
                scale: hud.visiblePhase ? 1.0 : 0.94
                transform: Translate {
                    y: hud.visiblePhase ? 0 : 10
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: 9
                        height: 9
                        radius: 4.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: pill.accentColor
                    }

                    Txt {
                        text: String(hud.currentWs).padStart(2, "0")
                        font.family: "Inter"
                        size: 16
                        font.weight: Font.Bold
                        color: pill.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Txt {
                        text: "·"
                        font.family: "Inter"
                        size: 16
                        color: Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Txt {
                        text: hud.room.name
                        font.family: "Inter Display"
                        size: 18
                        font.weight: Font.SemiBold
                        font.letterSpacing: 1.5
                        color: Theme.fgBright
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Txt {
                        text: hud.room.sub
                        font.family: "Inter"
                        size: 13
                        font.weight: Font.Normal
                        color: Qt.rgba(0.75, 0.79, 0.96, 0.74)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
