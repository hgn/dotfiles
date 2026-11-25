import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

// The dynamic island: one black shape that springs between sizes.
//   idle     clock
//   compact  clock + cover + equalizer while music plays
//   info     hover without media: big clock, date, weather
//   media    hover with media: cover, title, progress, controls
//   volume   OSD after a volume change
// Scroll = volume, middle click = play/pause, right click = do not disturb.
Item {
    id: island

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying)
            || ps.find(p => p.playbackState === MprisPlaybackState.Paused)
            || null
    }
    readonly property bool hovered: hover.hovered
    property bool osd: false

    readonly property string mode: hovered ? (player ? "media" : "info")
        : osd ? "volume"
        : player ? "compact" : "idle"

    readonly property var sizes: ({
        idle:    [190, 48],
        compact: [380, 48],
        info:    [580, 178],
        media:   [620, 172],
        volume:  [460, 64]
    })
    readonly property int targetW: sizes[mode][0]
    readonly property int targetH: sizes[mode][1]

    implicitWidth: shape.width
    implicitHeight: shape.height

    Connections {
        target: Store
        function onOsdSerialChanged() { island.osd = true; osdTimer.restart() }
    }
    Timer { id: osdTimer; interval: 1600; onTriggered: island.osd = false }

    // seconds only while the info view shows them; otherwise one tick a minute
    SystemClock { id: clock; precision: island.mode === "info" ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property var de: Qt.locale("de_DE")
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7))
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7)
    }

    // ---- the shape ----------------------------------------------------------
    Item {
        id: shape
        x: (island.width - width) / 2
        width: island.targetW + 2 * Theme.barFlare
        height: island.targetH
        Behavior on width { SpringAnimation { spring: 3.2; damping: 0.28; epsilon: 0.4 } }
        Behavior on height { SpringAnimation { spring: 3.2; damping: 0.30; epsilon: 0.4 } }

        DockedSurface {
            property real cornerRadius: island.mode === "idle" || island.mode === "compact" ? Theme.radius : 26
            Behavior on cornerRadius { NumberAnimation { duration: 220 } }

            anchors.fill: parent
            flare: Theme.barFlare
            radius: cornerRadius
            fillColor: island.mode === "idle" || island.mode === "compact" ? Theme.glass : Theme.island
            borderColor: Store.launcherOpen ? Theme.purple
                       : Store.dnd ? Qt.rgba(0.88, 0.69, 0.41, 0.55)
                       : Theme.border
            Behavior on fillColor   { ColorAnimation { duration: 180 } }
            Behavior on borderColor { ColorAnimation { duration: 180 } }
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: m => {
                if (m.button === Qt.RightButton) Store.dnd = !Store.dnd
                else if (m.button === Qt.MiddleButton) { if (island.player) island.player.togglePlaying() }
                else if (island.mode === "info") Store.run("gnome-calendar")
            }
            onWheel: w => Store.setVolume(Store.volume + (w.angleDelta.y > 0 ? 0.02 : -0.02))
        }

        // every mode is a layer that fades and scales in when active
        component Layer: Item {
            property string name
            readonly property bool on: island.mode === name
            anchors.fill: parent
            anchors.leftMargin: 14 + Theme.barFlare
            anchors.rightMargin: 14 + Theme.barFlare
            anchors.bottomMargin: 12
            anchors.topMargin: 6
            opacity: on ? 1 : 0
            scale: on ? 1 : 0.92
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: on ? 260 : 120 } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }

        // ---- idle ------------------------------------------------------------
        Layer {
            name: "idle"
            Row {
                anchors.centerIn: parent
                spacing: 10
                Icon { code: 0xF009B; size: 16; color: Theme.yellow; visible: Store.dnd }
                Txt {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: "white"; size: 20; font.weight: Font.Bold; font.letterSpacing: 1
                }
            }
        }

        // ---- compact: music playing ---------------------------------------------
        Layer {
            name: "compact"
            ClippingRectangle {
                id: miniArt
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 8
                color: Theme.hl
                Image {
                    anchors.fill: parent
                    source: island.player ? island.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
            Txt {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: "white"; size: 20; font.weight: Font.Bold; font.letterSpacing: 1
            }
            Row {
                id: eq
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 4; radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: island.player && island.player.isPlaying ? Theme.green : Theme.dim
                        height: 6
                        SequentialAnimation on height {
                            running: island.mode === "compact" && island.player && island.player.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 8 + (index * 7) % 16; duration: 180 + index * 70 }
                            NumberAnimation { to: 22 - (index * 5) % 12; duration: 220 + index * 40 }
                            NumberAnimation { to: 6; duration: 200 + index * 60 }
                        }
                    }
                }
            }
        }

        // ---- info: hover without media ---------------------------------------------
        Layer {
            name: "info"
            Column {
                anchors.centerIn: parent
                spacing: 10
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Txt {
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: "white"; size: 68; font.weight: Font.Bold
                    }
                    Txt {
                        text: Qt.formatDateTime(clock.date, "ss")
                        color: Theme.purple; size: 30; font.weight: Font.Bold
                        anchors.baseline: parent.children[0].baseline
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18
                    Txt {
                        text: island.de.toString(clock.date, "dddd, d. MMMM")
                        color: Theme.fg; size: 22; font.weight: Font.Medium
                    }
                    Txt {
                        text: "KW " + island.isoWeek(clock.date)
                        color: Theme.dim; size: 22
                    }
                    Txt { text: Store.weather; color: Theme.cyan; size: 22; visible: Store.weather !== "" }
                    Icon { code: 0xF009B; size: 21; color: Theme.yellow; visible: Store.dnd }
                }
            }
        }

        // ---- media: hover with a player -----------------------------------------------
        Layer {
            name: "media"
            Timer {
                interval: 1000; repeat: true
                running: island.mode === "media" && island.player && island.player.isPlaying
                onTriggered: island.player.positionChanged()
            }
            ClippingRectangle {
                id: art
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 124; height: 124; radius: 18
                color: Theme.hl
                Icon { anchors.centerIn: parent; code: 0xF0388; size: 48; color: Theme.dim }
                Image {
                    anchors.fill: parent
                    source: island.player ? island.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
            Column {
                anchors.left: art.right
                anchors.leftMargin: 18
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Txt {
                    width: parent.width
                    text: island.player ? (island.player.trackTitle || island.player.identity) : ""
                    color: "white"; size: 20; font.weight: Font.Bold
                }
                Txt {
                    width: parent.width
                    text: island.player ? [island.player.trackArtist, island.player.trackAlbum].filter(s => s).join("  ·  ") : ""
                    color: Theme.dim; size: 16
                }
                Item {
                    width: parent.width; height: 22
                    visible: island.player && island.player.lengthSupported && island.player.length > 0
                    Rectangle {
                        id: bar
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 6; radius: 3
                        color: Qt.rgba(1, 1, 1, 0.12)
                        Rectangle {
                            height: parent.height; radius: 3
                            width: island.player && island.player.length > 0
                                   ? parent.width * Math.min(1, island.player.position / island.player.length) : 0
                            color: Theme.green
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: island.player && island.player.canSeek
                        onClicked: m => island.player.position = island.player.length * (m.x / width)
                    }
                }
                Item {
                    width: parent.width; height: 34
                    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
                    Txt {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13; color: Theme.dim
                        text: island.player && island.player.lengthSupported
                              ? parent.fmt(island.player.position) + " / " + parent.fmt(island.player.length) : ""
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Chip {
                            implicitHeight: 34
                            Icon { code: 0xF04AE; size: 22 }
                            onClicked: if (island.player) island.player.previous()
                        }
                        Chip {
                            implicitHeight: 34
                            hoverColor: Qt.rgba(0.62, 0.81, 0.42, 0.25)
                            Icon {
                                code: island.player && island.player.isPlaying ? 0xF03E4 : 0xF040A
                                size: 24; color: Theme.green
                            }
                            onClicked: if (island.player) island.player.togglePlaying()
                        }
                        Chip {
                            implicitHeight: 34
                            Icon { code: 0xF04AD; size: 22 }
                            onClicked: if (island.player) island.player.next()
                        }
                    }
                    Txt {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13; color: Theme.dim
                        text: island.player ? island.player.identity : ""
                    }
                }
            }
        }

        // ---- volume OSD -----------------------------------------------------------------
        Layer {
            name: "volume"
            Row {
                anchors.centerIn: parent
                spacing: 16
                Icon {
                    code: Store.volumeIcon(Store.volume, Store.muted)
                    size: 26
                    color: Store.muted ? Theme.dim : Theme.purple
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    width: 290
                    anchors.verticalCenter: parent.verticalCenter
                    value: Store.muted ? 0 : Store.volume
                    onMoved: v => { Store.setVolume(v); osdTimer.restart() }
                }
                Txt {
                    width: 52
                    text: Store.muted ? "stumm" : Math.round(Store.volume * 100) + "%"
                    color: "white"; font.weight: Font.Bold
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
