import QtQuick
import Quickshell

// Technical brightness control popup (analogous to Mixer.qml): slider + quick presets.
PopupCard {
    id: bri
    open: Store.briOpen
    onDismissed: Store.briOpen = false

    readonly property int w: 320
    readonly property var presets: [
        { label: "20%",  v: 0.20 },
        { label: "45%",  v: 0.45 },
        { label: "70%",  v: 0.70 },
        { label: "100%", v: 1.00 }
    ]

    Item {
        width: bri.w; height: 24
        Txt { text: "Helligkeit"; size: 16; font.weight: Font.Bold; color: Theme.fgBright; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Store.brightness * 100) + "%"
            size: 16; font.weight: Font.Bold; color: Theme.yellow
        }
    }

    Row {
        spacing: 10
        Chip {
            implicitWidth: 36; implicitHeight: 36; padX: 0
            color: hovered ? Theme.hl : Theme.surface
            border.width: 1
            border.color: Theme.border
            Icon { code: Store.brightnessIcon(Store.brightness); size: 18; color: Theme.yellow }
            onClicked: Store.setBrightness(Store.brightness > 0.5 ? 0.25 : 0.85)
        }
        Slider {
            width: bri.w - 46
            anchors.verticalCenter: parent.verticalCenter
            thickness: 6
            from: Theme.yellow
            to: Theme.orange
            value: Store.brightness
            onMoved: v => Store.setBrightness(v)
        }
    }

    Row {
        spacing: 6
        Repeater {
            model: bri.presets
            Chip {
                id: presetBtn
                required property var modelData
                readonly property bool near: Math.abs(Store.brightness - modelData.v) < 0.04
                implicitWidth: (bri.w - 18) / 4
                implicitHeight: 30
                padX: 0
                color: near ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.20)
                     : hovered ? Theme.hl : Theme.surface
                border.width: 1
                border.color: near ? Theme.yellow : Theme.border
                Txt {
                    text: presetBtn.modelData.label
                    size: 13
                    font.weight: presetBtn.near ? Font.Bold : Font.Medium
                    color: presetBtn.near ? Theme.yellow : Theme.fg
                }
                onClicked: Store.setBrightness(presetBtn.modelData.v)
            }
        }
    }
}
