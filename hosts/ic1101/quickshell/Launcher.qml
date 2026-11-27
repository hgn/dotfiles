import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Application launcher (Super tap / Super+D):
// Detaches from the top center panel and glides smoothly into the upper-center
// of the screen as a frosted amethyst glass command palette; retracts back on close.
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
        readonly property int cardTargetW: 680
        readonly property int cardTargetH: 18 + 52 + 12 + rows * rowHeight + 12 + 22 + 14
        readonly property int restY: Math.round(height * 0.21)

        property string query: ""
        property var actionsOf: null
        property string savedQuery: ""
        property int current: 0
        property bool shown: false

        property color accent: actionsOf ? Theme.purple : Theme.blue
        Behavior on accent { ColorAnimation { duration: 180 } }

        readonly property var apps: DesktopEntries.applications.values
            .filter(e => !e.noDisplay)

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
            if (!shown) return
            shown = false
            closeTimer.restart()
        }

        Timer {
            id: closeTimer
            interval: 210
            onTriggered: Store.launcherOpen = false
        }
        Component.onCompleted: {
            Qt.callLater(() => {
                shown = true
                input.forceActiveFocus()
            })
        }

        // ---- dimmed backdrop --------------------------------------------------
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.02, 0.04, 0.44)
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        // ---- soft tether beam from the top clock panel during the drop --------
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: 3
            height: Math.max(0, card.y + 8)
            opacity: win.shown ? 0.0 : 0.45
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.purple }
                GradientStop { position: 0.6; color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.35) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ---- ambient radial aura behind the centered card ---------------------
        Shape {
            id: aura
            width: 1020
            height: 760
            anchors.horizontalCenter: parent.horizontalCenter
            y: card.y + card.height / 2 - height / 2
            opacity: win.shown ? 0.46 : 0
            scale: win.shown ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: aura.width / 2; centerY: aura.height / 2
                    focalX: centerX; focalY: centerY
                    centerRadius: aura.width / 2
                    focalRadius: 0
                    GradientStop { position: 0.0;  color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.28) }
                    GradientStop { position: 0.38; color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.12) }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
                startX: 0; startY: 0
                PathLine { x: aura.width; y: 0 }
                PathLine { x: aura.width; y: aura.height }
                PathLine { x: 0; y: aura.height }
                PathLine { x: 0; y: 0 }
            }
        }

        // ---- detaching card: starts at center panel (y=4, 200x40), springs to center ----
        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.shown ? win.restY : 4
            width: win.shown ? win.cardTargetW : 200
            height: win.shown ? win.cardTargetH : 40
            radius: win.shown ? 18 : 12
            color: Qt.rgba(0.082, 0.072, 0.145, 0.88)
            opacity: win.shown ? 1 : 0
            clip: false

            Behavior on y      { NumberAnimation { duration: win.shown ? 290 : 190; easing.type: win.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 0.55 } }
            Behavior on width  { NumberAnimation { duration: win.shown ? 270 : 180; easing.type: win.shown ? Easing.OutCubic : Easing.InCubic } }
            Behavior on height { NumberAnimation { duration: win.shown ? 230 : 180; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: win.shown ? 160 : 150; easing.type: Easing.OutCubic } }

            // Soft static amethyst/blue outward glow (no idle CPU loop)
            GE.RectangularGlow {
                anchors.fill: parent
                z: -3
                glowRadius: 44
                spread: 0.18
                cornerRadius: card.radius + glowRadius
                color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.42)
            }
            GE.RectangularGlow {
                anchors.fill: parent
                z: -2
                glowRadius: 18
                spread: 0.30
                cornerRadius: card.radius + glowRadius
                color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.45)
            }
            // Gradient border frame: blue -> purple -> cyan
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1.5
                z: -1
                radius: card.radius + 1.5
                opacity: 0.88
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.blue }
                    GradientStop { position: 0.5; color: Theme.purple }
                    GradientStop { position: 1.0; color: Theme.cyan }
                }
            }

            MouseArea { anchors.fill: parent }

            Item {
                id: inner
                anchors.fill: parent
                clip: true
                opacity: win.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: win.shown ? 200 : 90; easing.type: Easing.OutCubic } }

                // ---- search field ---------------------------------------------
                Rectangle {
                    id: field
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 18
                    height: 52
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: input.activeFocus ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.62) : Theme.border

                    Icon {
                        id: lens
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        code: win.actionsOf ? 0xF0142 : 0xF0349
                        size: 20
                        color: Theme.purple
                    }
                    Txt {
                        id: crumb
                        anchors.left: lens.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: win.actionsOf !== null
                        text: win.actionsOf ? win.actionsOf.name + "  ›" : ""
                        color: Theme.purple
                        size: 17
                        font.weight: Font.Bold
                    }
                    TextInput {
                        id: input
                        anchors.left: crumb.visible ? crumb.right : lens.right
                        anchors.leftMargin: 10
                        anchors.right: countBadge.left
                        anchors.rightMargin: 10
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
                            size: 19
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
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13
                        color: Theme.dim
                        text: win.results.length + (win.actionsOf ? " Aktionen" : " Apps")
                    }
                }

                // ---- results --------------------------------------------------
                ListView {
                    id: list
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.top: field.bottom
                    anchors.topMargin: 12
                    height: win.rows * win.rowHeight
                    clip: true
                    model: win.results
                    currentIndex: win.current
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 120
                    highlight: Rectangle {
                        radius: 12
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.28) }
                            GradientStop { position: 1; color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.20) }
                        }
                        border.width: 1
                        border.color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.40)
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isAction: modelData.kind === "action"
                        readonly property string iconSrc: win.iconFor(isAction && modelData.action.icon ? modelData.action.icon : modelData.entry.icon)
                        width: ListView.view.width
                        height: win.rowHeight

                        Item {
                            id: iconBox
                            anchors.left: parent.left
                            anchors.leftMargin: 12
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
                                size: 26
                                color: Theme.dim
                            }
                        }
                        Column {
                            anchors.left: iconBox.right
                            anchors.leftMargin: 14
                            anchors.right: badge.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Txt {
                                width: parent.width
                                text: row.isAction ? row.modelData.action.name : row.modelData.entry.name
                                color: row.index === win.current ? "white" : Theme.fgBright
                                size: 17
                                font.weight: row.index === win.current ? Font.SemiBold : Font.Medium
                            }
                            Txt {
                                width: parent.width
                                visible: text !== ""
                                text: row.isAction ? row.modelData.entry.name
                                      : (row.modelData.entry.genericName || row.modelData.entry.comment || "")
                                color: Theme.dim
                                size: 13
                            }
                        }
                        Txt {
                            id: badge
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !row.isAction && row.modelData.entry.actions.length > 0
                            text: "⇥ " + (visible ? row.modelData.entry.actions.length : "")
                            size: 12
                            color: Theme.dim
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
                    size: 16
                }

                // ---- subtle footer hints --------------------------------------
                Txt {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: 12
                    color: Theme.dim
                    text: win.actionsOf
                          ? "↵ ausführen   ·   ⌫ / Esc zurück"
                          : "↵ starten   ·   ↑↓ / Ctrl+JK bewegen   ·   ⇥ Aktionen   ·   Esc schließen"
                }
            }
        }
    }
}
