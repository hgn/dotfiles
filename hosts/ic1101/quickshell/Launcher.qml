import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Application launcher command palette with outward glow (Super tap / Super+D).
// Fuzzy + usage-ranked search; Up/Down or Ctrl+J/K/N/P, Enter to launch,
// Tab for desktop actions, Esc or outside click to close.
LazyLoader {
    id: loader
    active: Store.launcherOpen

    PanelWindow {
        id: win

        screen: {
            const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        }
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property int maxRows: 8
        readonly property int rowHeight: 54
        readonly property int rows: Math.max(1, Math.min(results.length, maxRows))

        property string query: ""
        property var actionsOf: null
        property string savedQuery: ""
        property int current: 0
        property bool shown: false

        // Gentle breathing pulse for the outward glow
        property real pulse: 0
        SequentialAnimation on pulse {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
        }
        // Subtle sweeping highlight along the top edge
        property real sweep: 0
        SequentialAnimation on sweep {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 2800; easing.type: Easing.InOutCubic }
            PauseAnimation { duration: 1600 }
        }

        property color accent: actionsOf ? Theme.purple : Theme.blue
        Behavior on accent { ColorAnimation { duration: 200 } }
        function tint(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }

        readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

        readonly property var results: {
            if (actionsOf)
                return actionsOf.actions.map(a => ({ kind: "action", entry: actionsOf, action: a }))
            const q = query.trim().toLowerCase()
            const scored = []
            for (const e of apps) {
                const s = score(e, q)
                if (s >= 0) scored.push({ kind: "app", entry: e, s: s })
            }
            scored.sort((a, b) => b.s - a.s || a.entry.name.localeCompare(b.entry.name))
            return scored.slice(0, 50)
        }
        onResultsChanged: current = 0

        function txt(x) { return x ? String(x).toLowerCase() : "" }
        function score(e, q) {
            const used = Store.usage[e.id] || 0
            const bonus = Math.min(250, 60 * Math.log2(1 + used))
            if (q === "") return bonus
            const name = txt(e.name)
            let s = -1
            if (name === q) s = 1000
            else if (name.startsWith(q)) s = 800
            else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 650
            else if (name.includes(q)) s = 500
            else {
                const extra = [e.genericName, e.keywords, e.categories, e.comment, e.id].map(txt).join(" ")
                if (extra.includes(q)) s = 300
                else {
                    let i = 0, gaps = 0, last = -1
                    for (let k = 0; k < name.length && i < q.length; k++) {
                        if (name[k] === q[i]) { if (last >= 0) gaps += k - last - 1; last = k; i++ }
                    }
                    if (i === q.length) s = Math.max(50, 250 - gaps * 10)
                }
            }
            return s < 0 ? -1 : s + bonus
        }
        function iconFor(name) {
            if (!name) return ""
            if (name.startsWith("/")) return "file://" + name
            return Quickshell.hasThemeIcon(name) ? Quickshell.iconPath(name) : ""
        }
        function launch(i) {
            const r = results[i]
            if (!r) return
            if (r.kind === "action") r.action.execute()
            else r.entry.execute()
            Store.bumpUsage(r.entry.id)
            close()
        }
        function enterActions(entry) {
            savedQuery = input.text
            actionsOf = entry
            input.text = ""
        }
        function leaveActions() {
            actionsOf = null
            input.text = savedQuery
        }
        function move(d) {
            if (results.length === 0) return
            current = (current + d + results.length) % results.length
            list.positionViewAtIndex(current, ListView.Contain)
        }
        function close() {
            shown = false
            closeTimer.restart()
        }

        Timer {
            id: closeTimer
            interval: 140
            onTriggered: Store.launcherOpen = false
        }
        Component.onCompleted: {
            shown = true
            input.forceActiveFocus()
        }

        // Backdrop
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.025, 0.04, 0.52)
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        // Ambient outward radial aura behind the launcher card
        Shape {
            id: aura
            width: 1180; height: 900
            anchors.horizontalCenter: parent.horizontalCenter
            y: card.y + card.height / 2 - height / 2
            opacity: win.shown ? 0.45 + 0.20 * win.pulse : 0
            scale: win.shown ? 1 : 0.85
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale   { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: aura.width / 2; centerY: aura.height / 2
                    focalX: centerX; focalY: centerY
                    centerRadius: aura.width / 2
                    focalRadius: 0
                    GradientStop { position: 0.0; color: win.tint(0.30) }
                    GradientStop { position: 0.36; color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.11) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                startX: 0; startY: 0
                PathLine { x: aura.width; y: 0 }
                PathLine { x: aura.width; y: aura.height }
                PathLine { x: 0; y: aura.height }
                PathLine { x: 0; y: 0 }
            }
        }

        // Centered launcher card with outward radiance + gradient border
        Rectangle {
            id: card
            width: 660
            height: 18 + 52 + 12 + win.rows * win.rowHeight + 12 + 20 + 14
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.14) + (win.shown ? 0 : 18)
            radius: 14
            color: Qt.rgba(0.075, 0.08, 0.115, 0.94)
            border.width: 0
            opacity: win.shown ? 1 : 0
            scale: win.shown ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.12 } }
            Behavior on y       { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on height  { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            // Wide outward breathing glow
            GE.RectangularGlow {
                anchors.fill: parent
                z: -3
                glowRadius: 56 + 14 * win.pulse
                spread: 0.22
                cornerRadius: card.radius + glowRadius
                color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.48 + 0.16 * win.pulse)
            }
            // Tighter blue/cyan core glow
            GE.RectangularGlow {
                anchors.fill: parent
                z: -2
                glowRadius: 22
                spread: 0.36
                cornerRadius: card.radius + glowRadius
                color: win.tint(0.55 + 0.15 * win.pulse)
            }
            // 2px horizontal gradient frame: blue -> purple -> cyan
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                radius: card.radius + 2
                opacity: 0.88 + 0.12 * win.pulse
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.blue }
                    GradientStop { position: 0.5; color: Theme.purple }
                    GradientStop { position: 1.0; color: Theme.cyan }
                }
            }

            MouseArea { anchors.fill: parent }

            // Sweeping highlight along the top edge
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
                    width: 240; height: 2; radius: 1
                    x: -width + win.sweep * (parent.width + width)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.lighter(win.accent, 1.35) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }

            // ---- search field -------------------------------------------------
            Rectangle {
                id: field
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 18
                height: 52
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: input.activeFocus ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.55) : Theme.border

                Icon {
                    id: lens
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    code: win.actionsOf ? 0xF0142 : 0xF0349
                    size: 20
                    color: Theme.purple
                }
                Txt {
                    id: crumb
                    anchors.left: lens.right; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.actionsOf !== null
                    text: win.actionsOf ? win.actionsOf.name + "  ›" : ""
                    color: Theme.purple; size: 17; font.weight: Font.Bold
                }
                TextInput {
                    id: input
                    anchors.left: crumb.visible ? crumb.right : lens.right
                    anchors.leftMargin: 10
                    anchors.right: countBadge.left; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: 19
                    color: "white"
                    selectionColor: Theme.purple
                    clip: true
                    onTextChanged: win.query = text

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === "" && !win.actionsOf
                        text: "Programm suchen …"
                        color: Theme.dim
                        size: 18
                    }

                    Keys.onPressed: e => {
                        const ctrl = e.modifiers & Qt.ControlModifier
                        if (e.key === Qt.Key_Escape) {
                            if (win.actionsOf) win.leaveActions()
                            else win.close()
                        } else if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                            win.move(1)
                        } else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                            win.move(-1)
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            win.launch(win.current)
                        } else if (e.key === Qt.Key_Tab) {
                            const r = win.results[win.current]
                            if (!win.actionsOf && r && r.entry.actions.length > 0) win.enterActions(r.entry)
                        } else if (win.actionsOf && (e.key === Qt.Key_Backtab || (e.key === Qt.Key_Backspace && input.text === ""))) {
                            win.leaveActions()
                        } else {
                            return
                        }
                        e.accepted = true
                    }
                }
                Txt {
                    id: countBadge
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    size: 12; color: Theme.dim
                    text: win.actionsOf ? "Esc zurück" : (win.results.length + " Treffer")
                }
            }

            // ---- results ------------------------------------------------------
            ListView {
                id: list
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 16; anchors.rightMargin: 16
                anchors.top: field.bottom; anchors.topMargin: 12
                height: win.rows * win.rowHeight
                clip: true
                model: win.results
                currentIndex: win.current
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 130
                highlightMoveVelocity: -1

                highlight: Item {
                    GE.RectangularGlow {
                        anchors.fill: parent
                        glowRadius: 10
                        spread: 0.12
                        cornerRadius: 10 + glowRadius
                        color: win.tint(0.24)
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.30) }
                            GradientStop { position: 1; color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.20) }
                        }
                        border.width: 1
                        border.color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.55)
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: parent.height * 0.52
                        radius: 2
                        color: Theme.cyan
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isAction: modelData.kind === "action"
                    readonly property bool active: index === win.current
                    readonly property string iconSrc: win.iconFor(isAction && modelData.action.icon ? modelData.action.icon : modelData.entry.icon)
                    width: ListView.view.width
                    height: win.rowHeight

                    Item {
                        id: iconBox
                        anchors.left: parent.left; anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 34
                        IconImage {
                            anchors.fill: parent
                            source: row.iconSrc
                            asynchronous: true
                            visible: row.iconSrc !== ""
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: row.iconSrc === ""
                            code: 0xF08C6
                            size: 24
                            color: Theme.dim
                        }
                    }

                    Column {
                        anchors.left: iconBox.right; anchors.leftMargin: 14
                        anchors.right: badge.left; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Txt {
                            width: parent.width
                            text: row.isAction ? row.modelData.action.name : row.modelData.entry.name
                            color: row.active ? "white" : Theme.fg
                            size: 16
                            font.weight: row.active ? Font.Bold : Font.Medium
                        }
                        Txt {
                            width: parent.width
                            visible: text !== ""
                            text: row.isAction ? row.modelData.entry.name
                                  : (row.modelData.entry.genericName || row.modelData.entry.comment || "")
                            color: Theme.dim
                            size: 12
                        }
                    }

                    Txt {
                        id: badge
                        anchors.right: parent.right; anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !row.isAction && row.modelData.entry.actions.length > 0
                        text: "⇥ " + (visible ? row.modelData.entry.actions.length : "")
                        size: 12; color: row.active ? Theme.cyan : Theme.dim
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.current = row.index
                        onClicked: win.launch(row.index)
                    }
                }
            }

            Txt {
                anchors.centerIn: list
                visible: win.results.length === 0
                text: "Keine Treffer für „" + win.query + "“"
                color: Theme.dim
            }

            // Subtle footer hints
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                size: 11
                color: Theme.dim
                text: win.actionsOf
                      ? "↑↓ wählen   ·   ↵ ausführen   ·   Esc zurück"
                      : "↑↓ wählen   ·   ↵ starten   ·   ⇥ Aktionen   ·   Esc schließen"
            }
        }
    }
}
