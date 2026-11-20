import QtQuick

// Technical floating OSD strip for volume, brightness and mic mute.
Rectangle {
    id: osd
    property bool shown: false

    width: 310
    height: 44
    radius: Theme.radius
    color: Theme.panel
    border.width: 1
    border.color: Store.osdKind === "brightness" ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.55)
                : Store.osdMuted ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.55)
                : Theme.borderStrong

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.96
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 130 } }
    Behavior on scale   { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Connections {
        target: Store
        function onOsdSerialChanged() {
            osd.shown = true
            hideTimer.restart()
        }
    }
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osd.shown = false
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            size: 18
            code: Store.osdKind === "brightness" ? Store.brightnessIcon(Store.osdValue)
                : Store.osdKind === "mic" ? (Store.osdMuted ? 0xF036D : 0xF036C)
                : Store.volumeIcon(Store.osdValue, Store.osdMuted)
            color: Store.osdKind === "brightness" ? Theme.yellow
                 : Store.osdMuted ? Theme.red
                 : Theme.purple
        }

        Slider {
            visible: Store.osdKind !== "mic"
            width: parent.width - 90
            anchors.verticalCenter: parent.verticalCenter
            from: Store.osdKind === "brightness" ? Theme.yellow : Theme.blue
            to:   Store.osdKind === "brightness" ? Theme.orange : Theme.purple
            value: Store.osdMuted ? 0 : Store.osdValue
            onMoved: v => {
                hideTimer.restart()
                if (Store.osdKind === "brightness") Store.setBrightness(v)
                else Store.setVolume(v)
            }
        }

        Txt {
            visible: Store.osdKind === "mic"
            width: parent.width - 90
            anchors.verticalCenter: parent.verticalCenter
            text: "Mikrofon"
            color: Theme.fg
        }

        Txt {
            width: 48
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            font.weight: Font.Bold
            color: Store.osdMuted ? Theme.red : Theme.fgBright
            text: Store.osdKind === "mic" ? (Store.osdMuted ? "stumm" : "aktiv")
                : Store.osdMuted ? "stumm"
                : Math.round(Store.osdValue * 100) + "%"
        }
    }
}
