import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Subtle bottom-center glass pill HUD that briefly announces the workspace room
// (1 Fokus · 2 Neon · 3 Aurora · 4 Glut · 5 Frost · 6 Phosphor) on switch.
Scope {
    id: hud

    property bool shown: false
    property bool visiblePhase: false
    property int lastWs: -1
    property int currentWs: 1

    readonly property var rooms: ({
        1: { name: "FOKUS",    accent: "#7aa2f7", sub: "Scrolling · ruhig" },
        2: { name: "NEON",     accent: "#ff7edb", sub: "Scrolling · Synthwave" },
        3: { name: "AURORA",   accent: "#73daca", sub: "Scrolling · Nordlicht" },
        4: { name: "GLUT",     accent: "#ff9e64", sub: "Monocle · still" },
        5: { name: "FROST",    accent: "#7dcfff", sub: "Scrolling · Eisglas" },
        6: { name: "PHOSPHOR", accent: "#33ff66", sub: "Scrolling · CRT" }
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
            margins.bottom: 44
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: pill.implicitWidth + 24
            implicitHeight: pill.implicitHeight + 24
            color: "transparent"
            WlrLayershell.namespace: "qs-ws-hud"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                id: pill
                anchors.centerIn: parent
                implicitWidth: row.implicitWidth + 44
                implicitHeight: 54
                radius: 27
                color: Qt.rgba(0.085, 0.075, 0.145, 0.72)
                border.width: 1.2
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.62)

                readonly property color accentColor: hud.room.accent

                opacity: hud.visiblePhase ? 1 : 0
                scale: hud.visiblePhase ? 1.0 : 0.94
                transform: Translate {
                    y: hud.visiblePhase ? 0 : 12
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 14

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: pill.accentColor
                    }

                    Txt {
                        text: String(hud.currentWs).padStart(2, "0")
                        font.family: "Inter"
                        size: 18
                        font.weight: Font.Bold
                        color: pill.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Txt {
                        text: "·"
                        font.family: "Inter"
                        size: 18
                        color: Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Txt {
                        text: hud.room.name
                        font.family: "Inter Display"
                        size: 20
                        font.weight: Font.SemiBold
                        font.letterSpacing: 1.6
                        color: Theme.fgBright
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Txt {
                        text: hud.room.sub
                        font.family: "Inter"
                        size: 14
                        font.weight: Font.Normal
                        color: Qt.rgba(0.75, 0.79, 0.96, 0.72)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
