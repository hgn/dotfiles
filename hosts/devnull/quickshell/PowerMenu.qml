import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Session menu as a command palette: a frosted glass card in the middle of
// the focused screen. Up/Down or Ctrl+J/K (or Tab) to move, Enter to run,
// L/S/E/R/P run directly, Esc or a click outside closes.
// Toggled by: qs ipc call shell power (wm-power, SUPER+Escape, bar button).
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
            { key: "L", icon: 0xF033E, title: "Sperren",     sub: "Bildschirm sperren",              color: Theme.blue,   cmd: "loginctl lock-session" },
            { key: "S", icon: 0xF0904, title: "Standby",     sub: "In den Bereitschaftsmodus",       color: Theme.purple, cmd: "systemctl suspend" },
            { key: "E", icon: 0xF0343, title: "Abmelden",    sub: "Sitzung beenden",                 color: Theme.cyan,   cmd: Store.home + "/.local/share/wm/bin/wm-power logout" },
            { key: "R", icon: 0xF0709, title: "Neustart",    sub: "System neu starten",              color: Theme.yellow, cmd: "systemctl reboot" },
            { key: "P", icon: 0xF0425, title: "Ausschalten", sub: "System herunterfahren",           color: Theme.red,    cmd: "systemctl poweroff" }
        ]
        property int current: 0
        property bool shown: false     // drives the in/out animation
        property string pending: ""    // command to run once the card is gone
        property bool firing: false    // short flash of the chosen row before closing

        // accent of the selected entry, faded when the selection changes
        property color accent: items[current].color
        Behavior on accent { ColorAnimation { duration: 220 } }
        function tint(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }

        // 0..1 breathing value for the outline / glow
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
        function run(i) {
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
            return (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "min"
        }

        // ---- backdrop ---------------------------------------------------------
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.02, 0.035, 0.55)
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
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) win.run(win.current)
                else {
                    const i = win.items.findIndex(it => it.key === e.text.toUpperCase())
                    if (i < 0 || ctrl) return
                    win.run(i)
                }
                e.accepted = true
            }
        }

        // ---- ambient glow behind the card, coloured like the selection --------
        Shape {
            id: aura
            width: 1500; height: 1100
            anchors.centerIn: parent
            opacity: win.shown ? 0.55 + 0.25 * win.pulse : 0
            scale: win.shown ? 1 : 0.8
            Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: aura.width / 2; centerY: aura.height / 2
                    focalX: centerX; focalY: centerY
                    centerRadius: aura.width / 2
                    focalRadius: 0
                    GradientStop { position: 0.0; color: win.tint(0.32) }
                    GradientStop { position: 0.35; color: win.tint(0.12) }
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
            width: 720
            height: content.implicitHeight + 2 * 28
            anchors.centerIn: parent
            anchors.verticalCenterOffset: win.shown ? 0 : 24
            radius: 26
            color: Qt.rgba(0.075, 0.08, 0.115, 0.92)
            border.width: 0
            opacity: win.shown ? 1 : 0
            scale: win.shown ? (win.firing ? 0.985 : 1) : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            // ---- radiance around the card (like the lock screen, but richer) ----
            // wide outer glow in the colour of the selected entry, breathing
            GE.RectangularGlow {
                anchors.fill: parent
                z: -3
                glowRadius: (win.firing ? 110 : 72 + 18 * win.pulse)
                spread: 0.24
                cornerRadius: card.radius + glowRadius
                color: win.tint(win.firing ? 0.95 : 0.62 + 0.18 * win.pulse)
            }
            // tighter blue/violet core glow, always there
            GE.RectangularGlow {
                anchors.fill: parent
                z: -2
                glowRadius: 28
                spread: 0.40
                cornerRadius: card.radius + glowRadius
                color: Qt.rgba(0.48, 0.64, 0.97, 0.60 + 0.15 * win.pulse)
            }
            // gradient frame: blue -> violet -> cyan, peeks out 2 px around the card
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

            // swallow clicks on the card so they do not close the menu
            MouseArea { anchors.fill: parent }

            // light running along the top edge
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
                    width: 260; height: 2; radius: 1
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
                anchors.margins: 28
                spacing: 0

                // header: clock left, greeting + uptime right
                Item {
                    width: parent.width
                    height: 86
                    Txt {
                        id: clock
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatTime(win.now, "HH:mm")
                        size: 58
                        font.weight: Font.Bold
                        color: "white"
                    }
                    Column {
                        anchors.left: clock.right
                        anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Txt {
                            text: win.now.toLocaleDateString(Qt.locale("de_DE"), "dddd, d. MMMM")
                            size: 17
                            color: Theme.fg
                        }
                        Txt {
                            text: "Bis später, " + Quickshell.env("USER") + "  ·  läuft seit " + win.uptime
                            size: 14
                            color: Theme.dim
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.06) }
                Item { width: 1; height: 14 }

                ListView {
                    id: list
                    width: parent.width
                    height: win.items.length * 66
                    interactive: false
                    model: win.items
                    currentIndex: win.current
                    highlightMoveDuration: 160
                    highlightMoveVelocity: -1
                    highlight: Item {
                        // soft shader glow breathing outwards, with a crisp outline on top
                        GE.RectangularGlow {
                            anchors.fill: parent
                            glowRadius: win.firing ? 22 : 8 + 10 * win.pulse
                            spread: 0.15
                            cornerRadius: 16 + glowRadius
                            color: win.tint(win.firing ? 0.55 : 0.16 + 0.22 * win.pulse)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: Qt.rgba(0.075, 0.08, 0.115, 1)   // card colour: hides the glow under the row
                            border.width: 1.5
                            border.color: win.tint(win.firing ? 1 : 0.35 + 0.45 * win.pulse)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: win.tint(win.firing ? 0.45 : 0.20 + 0.06 * win.pulse) }
                                GradientStop { position: 1; color: win.tint(win.firing ? 0.25 : 0.06) }
                            }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4; height: parent.height * (0.42 + 0.12 * win.pulse)
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
                        height: 66

                        // staggered slide-in when the menu opens
                        property real enter: 0
                        opacity: enter
                        transform: Translate { x: (1 - row.enter) * -28 }
                        SequentialAnimation on enter {
                            running: true
                            PauseAnimation { duration: 60 + row.index * 45 }
                            NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutCubic }
                        }

                        // little pop of the icon when it becomes selected
                        onActiveChanged: if (active) pop.restart()
                        SequentialAnimation {
                            id: pop
                            NumberAnimation { target: tile; property: "scale"; to: 1.14; duration: 110; easing.type: Easing.OutQuad }
                            NumberAnimation { target: tile; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                        }

                        Rectangle {
                            id: tile
                            anchors.left: parent.left
                            anchors.leftMargin: 22
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44; height: 44
                            radius: 12
                            color: Qt.rgba(row.modelData.color.r, row.modelData.color.g, row.modelData.color.b,
                                           row.active ? 0.22 + 0.08 * win.pulse : 0.10)
                            border.width: row.active ? 1 : 0
                            border.color: Qt.rgba(row.modelData.color.r, row.modelData.color.g, row.modelData.color.b, 0.45)
                            Icon {
                                anchors.centerIn: parent
                                code: row.modelData.icon
                                size: 24
                                color: row.active ? row.modelData.color : Qt.darker(row.modelData.color, 1.25)
                            }
                        }
                        Column {
                            anchors.left: tile.right
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Txt {
                                text: row.modelData.title
                                size: 19
                                color: row.active ? "white" : Theme.fg
                                font.weight: row.active ? Font.Bold : Font.Medium
                            }
                            Txt {
                                text: row.modelData.sub
                                size: 13
                                color: Theme.dim
                            }
                        }
                        // keycap
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34; height: 30
                            radius: 8
                            color: row.active ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, row.active ? 0.22 : 0.10)
                            Txt {
                                anchors.centerIn: parent
                                text: row.modelData.key
                                size: 14
                                font.weight: Font.Bold
                                color: row.active ? row.modelData.color : Theme.dim
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.current = row.index
                            onClicked: win.run(row.index)
                        }
                    }
                }

                Item { width: 1; height: 12 }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑↓ wählen    ↵ ausführen    L S E R P direkt    Esc schließen"
                    size: 12
                    color: Theme.dim
                }
            }
        }
    }
}
