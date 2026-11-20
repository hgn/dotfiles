import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Technical command-palette power menu with outward radiance glow.
// Up/Down, Ctrl+J/K, Tab, Enter, L/S/E/R/P direct, Esc or outside click closes.
LazyLoader {
    id: loader
    active: Store.powerOpen

    PanelWindow {
        id: win

        screen: {
            const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        }
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-power"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property var items: [
            { key: "L", icon: 0xF033E, title: "Sperren",     sub: "Bildschirm sperren",        color: Theme.blue,   cmd: "loginctl lock-session" },
            { key: "S", icon: 0xF0904, title: "Standby",     sub: "In den Bereitschaftsmodus", color: Theme.purple, cmd: "systemctl suspend" },
            { key: "E", icon: 0xF0343, title: "Abmelden",    sub: "Hyprland-Sitzung beenden",  color: Theme.cyan,   cmd: Store.home + "/.local/share/wm/bin/wm-power logout" },
            { key: "R", icon: 0xF0709, title: "Neustart",    sub: "System neu starten",        color: Theme.yellow, cmd: "systemctl reboot" },
            { key: "P", icon: 0xF0425, title: "Ausschalten", sub: "System herunterfahren",     color: Theme.red,    cmd: "systemctl poweroff" }
        ]
        property int current: 0
        property bool shown: false
        property string pending: ""
        property bool firing: false

        // Accent of the selected entry, smoothly faded when switching rows
        property color accent: items[current].color
        Behavior on accent { ColorAnimation { duration: 220 } }
        function tint(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }

        // 0..1 breathing pulse for the outward glow
        property real pulse: 0
        SequentialAnimation on pulse {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1300; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 1300; easing.type: Easing.InOutSine }
        }
        // 0..1 position of the light sweeping along the top edge
        property real sweep: 0
        SequentialAnimation on sweep {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 2600; easing.type: Easing.InOutCubic }
            PauseAnimation { duration: 1400 }
        }

        function move(d) { current = (current + d + items.length) % items.length }
        function runAction(i) {
            if (pending !== "") return
            current = i
            pending = items[i].cmd
            firing = true
            fireTimer.restart()
        }
        function close() { shown = false; closeTimer.restart() }

        Timer { id: fireTimer; interval: 180; onTriggered: win.close() }
        Timer {
            id: closeTimer
            interval: 190
            onTriggered: {
                const cmd = win.pending
                Store.powerOpen = false
                if (cmd !== "") Store.run(cmd)
            }
        }
        Component.onCompleted: { shown = true; keys.forceActiveFocus() }

        // ---- uptime / clock ---------------------------------------------------
        FileView { id: uptimeFile; path: "/proc/uptime"; blockLoading: true }
        property date now: new Date()
        Timer { interval: 1000; running: true; repeat: true; onTriggered: { win.now = new Date(); uptimeFile.reload() } }
        readonly property string uptime: {
            void win.now
            const s = Math.floor(parseFloat(uptimeFile.text()) || 0)
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
            return (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m"
        }

        // ---- backdrop ---------------------------------------------------------
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.02, 0.035, 0.56)
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        // ---- keyboard ---------------------------------------------------------
        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                const ctrl = e.modifiers & Qt.ControlModifier
                if (e.key === Qt.Key_Escape) win.close()
                else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || (ctrl && e.key === Qt.Key_J)) win.move(1)
                else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (ctrl && e.key === Qt.Key_K)) win.move(-1)
                else if (e.key === Qt.Key_Home) win.current = 0
                else if (e.key === Qt.Key_End) win.current = win.items.length - 1
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) win.runAction(win.current)
                else {
                    const i = win.items.findIndex(it => it.key === e.text.toUpperCase())
                    if (i < 0 || ctrl) return
                    win.runAction(i)
                }
                e.accepted = true
            }
        }

        // ---- ambient outward radial aura behind the card ----------------------
        Shape {
            id: aura
            width: 1120; height: 820
            anchors.centerIn: parent
            opacity: win.shown ? 0.55 + 0.25 * win.pulse : 0
            scale: win.shown ? 1 : 0.82
            Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: aura.width / 2; centerY: aura.height / 2
                    focalX: centerX; focalY: centerY
                    centerRadius: aura.width / 2
                    focalRadius: 0
                    GradientStop { position: 0.0; color: win.tint(0.34) }
                    GradientStop { position: 0.35; color: win.tint(0.13) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                startX: 0; startY: 0
                PathLine { x: aura.width; y: 0 }
                PathLine { x: aura.width; y: aura.height }
                PathLine { x: 0; y: aura.height }
                PathLine { x: 0; y: 0 }
            }
        }

        // ---- card -------------------------------------------------------------
        Rectangle {
            id: card
            width: 560
            height: content.implicitHeight + 2 * 22
            anchors.centerIn: parent
            anchors.verticalCenterOffset: win.shown ? 0 : 20
            radius: 14
            color: Qt.rgba(0.075, 0.08, 0.115, 0.93)
            border.width: 0
            opacity: win.shown ? 1 : 0
            scale: win.shown ? (win.firing ? 0.985 : 1) : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            // Wide outward glow in the selected entry's colour, breathing
            GE.RectangularGlow {
                anchors.fill: parent
                z: -3
                glowRadius: (win.firing ? 95 : 62 + 16 * win.pulse)
                spread: 0.24
                cornerRadius: card.radius + glowRadius
                color: win.tint(win.firing ? 0.95 : 0.62 + 0.18 * win.pulse)
            }
            // Tighter blue/violet core glow
            GE.RectangularGlow {
                anchors.fill: parent
                z: -2
                glowRadius: 24
                spread: 0.38
                cornerRadius: card.radius + glowRadius
                color: Qt.rgba(0.48, 0.64, 0.97, 0.58 + 0.15 * win.pulse)
            }
            // Gradient frame: blue -> violet -> cyan, 2 px around the card
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                radius: card.radius + 2
                opacity: 0.90 + 0.10 * win.pulse
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.blue }
                    GradientStop { position: 0.5; color: Theme.purple }
                    GradientStop { position: 1.0; color: Theme.cyan }
                }
            }

            MouseArea { anchors.fill: parent }

            // Light sweeping along the top edge
            Item {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: parent.radius
                anchors.rightMargin: parent.radius
                anchors.topMargin: 1
                height: 2
                clip: true
                Rectangle {
                    width: 220; height: 2; radius: 1
                    x: -width + win.sweep * (parent.width + width)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.lighter(win.accent, 1.3) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: 22
                spacing: 0

                // Header: clock left, date + host/uptime/battery right
                Item {
                    width: parent.width
                    height: 66
                    Txt {
                        id: clk
                        anchors.left: parent.left; anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatTime(win.now, "HH:mm")
                        size: 44; font.weight: Font.Bold; color: "white"
                    }
                    Column {
                        anchors.left: clk.right; anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Txt {
                            text: win.now.toLocaleDateString(Qt.locale("de_DE"), "dddd, d. MMMM")
                            size: 15; color: Theme.fg
                        }
                        Txt {
                            text: "ic1101  ·  up " + win.uptime + (Store.batPresent ? ("  ·  BAT " + Store.batPercent + "%") : "")
                            size: 12; color: Theme.dim
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }
                Item { width: 1; height: 12 }

                ListView {
                    width: parent.width
                    height: win.items.length * 56
                    interactive: false
                    model: win.items
                    currentIndex: win.current
                    highlightMoveDuration: 150
                    highlightMoveVelocity: -1

                    highlight: Item {
                        GE.RectangularGlow {
                            anchors.fill: parent
                            glowRadius: win.firing ? 20 : 8 + 8 * win.pulse
                            spread: 0.15
                            cornerRadius: 10 + glowRadius
                            color: win.tint(win.firing ? 0.55 : 0.16 + 0.22 * win.pulse)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Qt.rgba(0.075, 0.08, 0.115, 1)
                            border.width: 1.5
                            border.color: win.tint(win.firing ? 1 : 0.35 + 0.45 * win.pulse)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: win.tint(win.firing ? 0.45 : 0.20 + 0.06 * win.pulse) }
                                GradientStop { position: 1; color: win.tint(win.firing ? 0.25 : 0.06) }
                            }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: parent.height * (0.44 + 0.12 * win.pulse)
                            radius: 2
                            color: win.accent
                        }
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool active: index === win.current
                        width: ListView.view.width
                        height: 56

                        property real enter: 0
                        opacity: enter
                        transform: Translate { x: (1 - row.enter) * -22 }
                        SequentialAnimation on enter {
                            running: true
                            PauseAnimation { duration: 50 + row.index * 40 }
                            NumberAnimation { to: 1; duration: 280; easing.type: Easing.OutCubic }
                        }

                        onActiveChanged: if (active) pop.restart()
                        SequentialAnimation {
                            id: pop
                            NumberAnimation { target: tile; property: "scale"; to: 1.12; duration: 100; easing.type: Easing.OutQuad }
                            NumberAnimation { target: tile; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                        }

                        Rectangle {
                            id: tile
                            anchors.left: parent.left; anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36; height: 36; radius: 8
                            color: Qt.rgba(row.modelData.color.r, row.modelData.color.g, row.modelData.color.b,
                                           row.active ? 0.22 + 0.08 * win.pulse : 0.10)
                            border.width: row.active ? 1 : 0
                            border.color: Qt.rgba(row.modelData.color.r, row.modelData.color.g, row.modelData.color.b, 0.45)
                            Icon {
                                anchors.centerIn: parent
                                code: row.modelData.icon
                                size: 20
                                color: row.active ? row.modelData.color : Qt.darker(row.modelData.color, 1.25)
                            }
                        }

                        Column {
                            anchors.left: tile.right; anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Txt {
                                text: row.modelData.title
                                size: 16
                                font.weight: row.active ? Font.Bold : Font.Medium
                                color: row.active ? "white" : Theme.fg
                            }
                            Txt {
                                text: row.modelData.sub
                                size: 12
                                color: Theme.dim
                            }
                        }

                        // Keycap
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30; height: 26; radius: 6
                            color: row.active ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, row.active ? 0.24 : 0.10)
                            Txt {
                                anchors.centerIn: parent
                                text: row.modelData.key
                                size: 13; font.weight: Font.Bold
                                color: row.active ? row.modelData.color : Theme.dim
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.current = row.index
                            onClicked: win.runAction(row.index)
                        }
                    }
                }

                Item { width: 1; height: 10 }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑↓ wählen   ·   ↵ ausführen   ·   L S E R P direkt   ·   Esc schließen"
                    size: 11
                    color: Theme.dim
                }
            }
        }
    }
}
