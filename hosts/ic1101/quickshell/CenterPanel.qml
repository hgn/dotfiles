import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

// Center floating glass panel that smoothly enlarges on hover:
//   idle     clock + date | compact media (if playing) | weather | DND
//   info     hover without media: big clock + seconds, full date, KW, weather details
//   media    hover with media: album art, title/artist, seek bar, prev/play/next
// Scroll = volume, middle click = play/pause, right click = DND.
Item {
    id: root

    y: Theme.barMarginTop
    implicitWidth: shape.width
    implicitHeight: shape.height

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying)
            || ps.find(p => p.playbackState === MprisPlaybackState.Paused)
            || null
    }

    property bool expanded: false
    readonly property string mode: expanded ? (player ? "media" : "info") : "idle"

    // Small close delay avoids jitter if the pointer brushes an edge while morphing
    Timer {
        id: collapseTimer
        interval: 120
        onTriggered: if (!hover.hovered) root.expanded = false
    }

    SystemClock {
        id: clock
        precision: root.mode === "info" ? SystemClock.Seconds : SystemClock.Minutes
    }
    readonly property var de: Qt.locale("de_DE")
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7))
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7)
    }

    readonly property int idleW: Math.max(220, idleRow.implicitWidth + 16)
    readonly property int targetW: mode === "media" ? 500 : mode === "info" ? 470 : idleW
    readonly property int targetH: mode === "media" ? 156 : mode === "info" ? 148 : Theme.barHeight

    Rectangle {
        id: shape
        x: (root.width - width) / 2
        width: root.targetW
        height: root.targetH
        radius: root.expanded ? 10 : Theme.radius
        color: root.expanded ? Theme.panel : Theme.bg
        border.width: 1
        border.color: Store.dnd ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.55)
                    : root.expanded ? Theme.borderStrong
                    : Theme.border
        clip: true

        Behavior on width  { SpringAnimation { spring: 4.0; damping: 0.34; epsilon: 0.4 } }
        Behavior on height { SpringAnimation { spring: 4.0; damping: 0.36; epsilon: 0.4 } }
        Behavior on radius { NumberAnimation { duration: 180 } }
        Behavior on color  { ColorAnimation  { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        // Subtle 2px top accent strip visible when enlarged
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            opacity: root.expanded ? 0.9 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.blue }
                GradientStop { position: 0.5; color: Theme.purple }
                GradientStop { position: 1.0; color: Theme.cyan }
            }
        }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    collapseTimer.stop()
                    root.expanded = true
                } else {
                    collapseTimer.restart()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: m => {
                if (m.button === Qt.RightButton) Store.dnd = !Store.dnd
                else if (m.button === Qt.MiddleButton) { if (root.player) root.player.togglePlaying() }
                else if (root.mode === "info") Store.run("xdg-open 'https://wttr.in/?lang=de'")
            }
            onWheel: w => Store.setVolume(Store.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
        }

        component Layer: Item {
            property string name
            readonly property bool on: root.mode === name
            anchors.fill: parent
            opacity: on ? 1 : 0
            scale: on ? 1 : 0.95
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: on ? 190 : 90 } }
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // ---- idle: compact technical bar strip --------------------------------
        Layer {
            name: "idle"
            Row {
                id: idleRow
                anchors.centerIn: parent
                spacing: 4

                Chip {
                    padX: 10
                    Row {
                        spacing: 7
                        anchors.verticalCenter: parent.verticalCenter
                        Txt {
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: Theme.fgBright
                            font.weight: Font.Bold
                        }
                        Txt { text: "·"; color: Theme.dim }
                        Txt {
                            text: root.de.toString(clock.date, "ddd, dd.MM.")
                            color: Theme.fg
                        }
                    }
                    onClicked: m => {
                        if (m.button === Qt.RightButton) Store.dnd = !Store.dnd
                    }
                }

                Divider { visible: root.player !== null }
                Chip {
                    visible: root.player !== null
                    padX: 8
                    Icon {
                        code: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                        size: Theme.fontSize + 1
                        color: root.player && root.player.isPlaying ? Theme.green : Theme.dim
                    }
                    Txt {
                        text: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
                        color: Theme.fg
                        width: Math.min(implicitWidth, 140)
                    }
                    onClicked: m => {
                        if (!root.player) return
                        if (m.button === Qt.RightButton) root.player.next()
                        else if (m.button === Qt.MiddleButton) root.player.previous()
                        else root.player.togglePlaying()
                    }
                }

                Divider { visible: Store.weather !== "" }
                Chip {
                    visible: Store.weather !== ""
                    padX: 9
                    Txt { text: Store.weather; color: Theme.cyan }
                    onClicked: Store.run("xdg-open 'https://wttr.in/?lang=de'")
                }

                Divider { visible: Store.dnd }
                Chip {
                    visible: Store.dnd
                    padX: 7
                    Icon { code: 0xF009B; size: Theme.fontSize + 1; color: Theme.yellow }
                    onClicked: Store.dnd = false
                }
            }
        }

        // ---- info: enlarged clock, date, KW, weather details ------------------
        Layer {
            name: "info"
            Column {
                anchors.centerIn: parent
                spacing: 8

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Txt {
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: "white"; size: 48; font.weight: Font.Bold
                    }
                    Txt {
                        text: Qt.formatDateTime(clock.date, "ss")
                        color: Theme.purple; size: 22; font.weight: Font.Bold
                        anchors.baseline: parent.children[0].baseline
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14
                    Txt {
                        text: root.de.toString(clock.date, "dddd, d. MMMM")
                        color: Theme.fgBright; size: 16; font.weight: Font.Medium
                    }
                    Txt {
                        text: "KW " + root.isoWeek(clock.date)
                        color: Theme.dim; size: 15
                    }
                    Txt {
                        text: Store.weather
                        color: Theme.cyan; size: 16
                        visible: Store.weather !== ""
                    }
                    Icon {
                        code: 0xF009B; size: 16; color: Theme.yellow
                        visible: Store.dnd
                    }
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, 430)
                    visible: Store.weatherLong !== ""
                    text: Store.weatherLong.replace(/\n+/g, "  ·  ")
                    color: Theme.dim; size: 12
                }
            }
        }

        // ---- media: enlarged cover art, track info, seek bar, controls --------
        Layer {
            name: "media"
            Timer {
                interval: 1000; repeat: true
                running: root.mode === "media" && root.player && root.player.isPlaying
                onTriggered: root.player.positionChanged()
            }

            Item {
                anchors.fill: parent
                anchors.margins: 16

                ClippingRectangle {
                    id: art
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 104; height: 104; radius: 8
                    color: Theme.surface
                    Icon { anchors.centerIn: parent; code: 0xF0388; size: 40; color: Theme.dim }
                    Image {
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    anchors.left: art.right; anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Txt {
                        width: parent.width
                        text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                        color: "white"; size: 17; font.weight: Font.Bold
                    }
                    Txt {
                        width: parent.width
                        text: root.player ? [root.player.trackArtist, root.player.trackAlbum].filter(s => s).join("  ·  ") : ""
                        color: Theme.dim; size: 13
                    }

                    Item {
                        width: parent.width; height: 18
                        visible: root.player && root.player.lengthSupported && root.player.length > 0
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 5; radius: 2
                            color: Qt.rgba(1, 1, 1, 0.12)
                            Rectangle {
                                height: parent.height; radius: 2
                                width: root.player && root.player.length > 0
                                       ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                                color: Theme.green
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.player && root.player.canSeek
                            onClicked: m => root.player.position = root.player.length * (m.x / width)
                        }
                    }

                    Item {
                        width: parent.width; height: 32
                        function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

                        Txt {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            size: 12; color: Theme.dim
                            text: root.player && root.player.lengthSupported
                                  ? parent.fmt(root.player.position) + " / " + parent.fmt(root.player.length) : ""
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Chip {
                                implicitHeight: 30; padX: 8
                                Icon { code: 0xF04AE; size: 18 }
                                onClicked: if (root.player) root.player.previous()
                            }
                            Chip {
                                implicitHeight: 30; padX: 8
                                hoverColor: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.22)
                                Icon {
                                    code: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                                    size: 20; color: Theme.green
                                }
                                onClicked: if (root.player) root.player.togglePlaying()
                            }
                            Chip {
                                implicitHeight: 30; padX: 8
                                Icon { code: 0xF04AD; size: 18 }
                                onClicked: if (root.player) root.player.next()
                            }
                        }
                        Txt {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            size: 12; color: Theme.dim
                            text: root.player ? root.player.identity : ""
                        }
                    }
                }
            }
        }
    }
}
