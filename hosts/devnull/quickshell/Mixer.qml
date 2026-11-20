import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

// Volume mixer: master, output device, per-application streams.
PopupCard {
    id: mixer
    open: Store.mixerOpen
    onDismissed: Store.mixerOpen = false

    readonly property int w: 440

    component Heading: Txt {
        size: 13
        color: Theme.dim
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.5
    }

    Item {
        width: mixer.w; height: 30
        Txt { text: "Lautstärke"; size: 21; font.weight: Font.Bold; color: "white"; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Store.muted ? "stumm" : Math.round(Store.volume * 100) + "%"
            size: 21; font.weight: Font.Bold; color: Store.muted ? Theme.dim : Theme.purple
        }
    }

    Row {
        spacing: 14
        Chip {
            implicitWidth: 46; implicitHeight: 46
            color: Store.muted ? Qt.rgba(0.97, 0.46, 0.56, 0.25) : (hovered ? Theme.hl : Qt.rgba(1, 1, 1, 0.06))
            Icon { code: Store.volumeIcon(Store.volume, Store.muted); size: 24; color: Store.muted ? Theme.red : Theme.purple }
            onClicked: Store.toggleMute()
        }
        Slider {
            width: mixer.w - 60
            anchors.verticalCenter: parent.verticalCenter
            thickness: 10
            value: Store.muted ? 0 : Store.volume
            onMoved: v => Store.setVolume(v)
        }
    }

    Heading { text: "Ausgabe" }

    Column {
        spacing: 6
        Repeater {
            model: Store.sinks
            Rectangle {
                id: sinkRow
                required property var modelData
                readonly property bool current: Store.sink && modelData.id === Store.sink.id
                readonly property bool headset: /usb|bluez|jabra|headset|headphone/i.test(modelData.name + " " + modelData.description)
                width: mixer.w; height: 48; radius: 14
                color: current ? Qt.rgba(0.73, 0.60, 0.97, 0.16) : (sinkMouse.containsMouse ? Theme.hl : "transparent")
                border.width: current ? 1 : 0
                border.color: Qt.rgba(0.73, 0.60, 0.97, 0.4)
                Behavior on color { ColorAnimation { duration: 150 } }
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Icon { code: sinkRow.headset ? 0xF02CB : 0xF04C3; color: sinkRow.current ? Theme.purple : Theme.fg }
                    Txt {
                        width: mixer.w - 100
                        text: sinkRow.modelData.description || sinkRow.modelData.name
                        color: sinkRow.current ? "white" : Theme.fg
                    }
                }
                Icon {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    code: 0xF012C; color: Theme.purple; visible: sinkRow.current
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
        spacing: 12
        visible: Store.streams.length > 0
        Repeater {
            model: Store.streams
            Row {
                id: streamRow
                required property var modelData
                readonly property var audio: modelData.audio
                readonly property var props: modelData.properties || {}
                spacing: 12
                Chip {
                    implicitWidth: 40; implicitHeight: 40
                    color: streamRow.audio && streamRow.audio.muted ? Qt.rgba(0.97, 0.46, 0.56, 0.25)
                                                                    : (hovered ? Theme.hl : Qt.rgba(1, 1, 1, 0.06))
                    IconImage {
                        implicitSize: 22
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
                        width: mixer.w - 52; height: 20
                        Txt { text: Store.nodeName(streamRow.modelData); size: 15; width: parent.width - 60 }
                        Txt {
                            anchors.right: parent.right
                            text: streamRow.audio ? Math.round(streamRow.audio.volume * 100) + "%" : ""
                            size: 14; color: Theme.dim
                        }
                    }
                    Slider {
                        width: mixer.w - 52
                        thickness: 6
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
        implicitHeight: 40
        color: hovered ? Theme.hl : Qt.rgba(1, 1, 1, 0.05)
        Icon { code: 0xF0493; size: 18; color: Theme.dim }
        Txt { text: "Erweiterter Mixer"; size: 15; color: Theme.fg }
        onClicked: { Store.mixerOpen = false; Store.run("pavucontrol") }
    }
}
