import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

// Technical PipeWire mixer popup: master volume, output sinks, per-app streams.
PopupCard {
    id: mixer
    open: Store.mixerOpen
    onDismissed: Store.mixerOpen = false

    readonly property int w: 360

    component Heading: Txt {
        size: 11
        color: Theme.dim
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.4
    }

    Item {
        width: mixer.w; height: 24
        Txt { text: "Audio"; size: 16; font.weight: Font.Bold; color: Theme.fgBright; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Store.muted ? "stumm" : Math.round(Store.volume * 100) + "%"
            size: 16; font.weight: Font.Bold; color: Store.muted ? Theme.dim : Theme.purple
        }
    }

    Row {
        spacing: 10
        Chip {
            implicitWidth: 36; implicitHeight: 36
            padX: 0
            color: Store.muted ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25)
                 : (hovered ? Theme.hl : Theme.surface)
            border.width: 1
            border.color: Store.muted ? Theme.red : Theme.border
            Icon { code: Store.volumeIcon(Store.volume, Store.muted); size: 18; color: Store.muted ? Theme.red : Theme.purple }
            onClicked: Store.toggleMute()
        }
        Slider {
            width: mixer.w - 46
            anchors.verticalCenter: parent.verticalCenter
            thickness: 6
            value: Store.muted ? 0 : Store.volume
            onMoved: v => Store.setVolume(v)
        }
    }

    Heading { text: "Ausgabe" }

    Column {
        spacing: 4
        Repeater {
            model: Store.sinks
            Rectangle {
                id: sinkRow
                required property var modelData
                readonly property bool current: Store.sink && modelData.id === Store.sink.id
                readonly property bool headset: /usb|bluez|jabra|headset|headphone/i.test(modelData.name + " " + modelData.description)
                width: mixer.w; height: 38; radius: Theme.chipRadius
                color: current ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.16)
                     : (sinkMouse.containsMouse ? Theme.hl : "transparent")
                border.width: current ? 1 : 0
                border.color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)

                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Icon { code: sinkRow.headset ? 0xF02CB : 0xF04C3; size: 16; color: sinkRow.current ? Theme.purple : Theme.fg }
                    Txt {
                        width: mixer.w - 72
                        size: 13
                        text: sinkRow.modelData.description || sinkRow.modelData.name
                        color: sinkRow.current ? Theme.fgBright : Theme.fg
                    }
                }
                Icon {
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    code: 0xF012C; size: 16; color: Theme.purple; visible: sinkRow.current
                }
                MouseArea {
                    id: sinkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                }
            }
        }
    }

    Heading { text: "Programme"; visible: Store.streams.length > 0 }

    Column {
        spacing: 8
        visible: Store.streams.length > 0
        Repeater {
            model: Store.streams
            Row {
                id: streamRow
                required property var modelData
                readonly property var audio: modelData.audio
                readonly property var props: modelData.properties || {}
                spacing: 10
                Chip {
                    implicitWidth: 32; implicitHeight: 32; padX: 0
                    color: streamRow.audio && streamRow.audio.muted
                           ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25)
                           : (hovered ? Theme.hl : Theme.surface)
                    IconImage {
                        implicitSize: 18
                        source: {
                            for (const c of [streamRow.props["application.icon-name"],
                                             (streamRow.props["application.name"] || "").toLowerCase(),
                                             "audio-x-generic"])
                                if (c && Quickshell.hasThemeIcon(c)) return Quickshell.iconPath(c)
                            return ""
                        }
                        opacity: streamRow.audio && streamRow.audio.muted ? 0.4 : 1
                    }
                    onClicked: if (streamRow.audio) streamRow.audio.muted = !streamRow.audio.muted
                }
                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Item {
                        width: mixer.w - 42; height: 18
                        Txt { text: Store.nodeName(streamRow.modelData); size: 13; width: parent.width - 48 }
                        Txt {
                            anchors.right: parent.right
                            text: streamRow.audio ? Math.round(streamRow.audio.volume * 100) + "%" : ""
                            size: 12; color: Theme.dim
                        }
                    }
                    Slider {
                        width: mixer.w - 42
                        thickness: 4
                        from: Theme.cyan
                        to: Theme.blue
                        value: streamRow.audio ? (streamRow.audio.muted ? 0 : streamRow.audio.volume) : 0
                        onMoved: v => { if (streamRow.audio) { streamRow.audio.muted = false; streamRow.audio.volume = v } }
                    }
                }
            }
        }
    }

    Chip {
        implicitWidth: mixer.w
        implicitHeight: 32
        color: hovered ? Theme.hl : Theme.surface
        border.width: 1
        border.color: Theme.border
        Icon { code: 0xF0493; size: 15; color: Theme.dim }
        Txt { text: "pavucontrol"; size: 13; color: Theme.fg }
        onClicked: { Store.mixerOpen = false; Store.run("pavucontrol") }
    }
}
