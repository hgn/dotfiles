import QtQuick
import Quickshell

// Technical system telemetry popup: CPU/Temp 3-min graph, RAM, Load, Battery, htop.
PopupCard {
    id: sys
    open: Store.sysOpen
    onDismissed: Store.sysOpen = false

    readonly property int w: 380

    component Stat: Column {
        property alias label: lbl.text
        property alias value: val.text
        property color tint: Theme.fg
        spacing: 2
        Txt { id: lbl; size: 11; color: Theme.dim; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
        Txt { id: val; size: 20; font.weight: Font.Bold; color: parent.tint }
    }

    Item {
        width: sys.w; height: 22
        Txt { text: "System  ·  ic1101"; size: 15; font.weight: Font.Bold; color: Theme.fgBright; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: Store.powerProfile; size: 12; color: Store.powerProfileColor(Store.powerProfile)
        }
    }

    Row {
        spacing: 26
        Stat { label: "CPU"; value: Math.round(Store.cpu * 100) + "%"; tint: Theme.blue }
        Stat { label: "Temp"; value: Math.round(Store.temp) + " °C"; tint: Store.temp > 85 ? Theme.red : Theme.yellow }
        Stat { label: "Load"; value: Store.load.split("  ")[0] || "-"; tint: Theme.cyan }
        Stat {
            visible: Store.batPresent
            label: "Akku"
            value: Store.batPercent + "%"
            tint: Store.batPercent <= 15 ? Theme.red : Theme.green
        }
    }

    Rectangle {
        width: sys.w; height: 104; radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        Repeater {
            model: 3
            Rectangle {
                required property int index
                x: 0; width: parent.width; height: 1
                y: (index + 1) * parent.height / 4
                color: Qt.rgba(1, 1, 1, 0.05)
            }
        }
        Spark {
            anchors.fill: parent; anchors.margins: 6
            values: Store.tempHistory
            stroke: Theme.yellow
            lineWidth: 1.4
        }
        Spark {
            anchors.fill: parent; anchors.margins: 6
            values: Store.cpuHistory
            stroke: Theme.blue
            lineWidth: 2.0
        }
        Txt {
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
            text: "CPU · Temp · 3 min"; size: 10; color: Theme.dim
        }
    }

    Column {
        spacing: 6
        Item {
            width: sys.w; height: 18
            Txt { text: "RAM"; size: 12; color: Theme.dim }
            Txt {
                anchors.right: parent.right
                text: Store.memUsed.toFixed(1) + " / " + Store.memTotal.toFixed(0) + " GiB"
                size: 12; color: Theme.purple
            }
        }
        Rectangle {
            width: sys.w; height: 7; radius: 3
            color: Qt.rgba(1, 1, 1, 0.10)
            Rectangle {
                height: parent.height; radius: 3
                width: parent.width * Math.min(1, Store.memUsed / Store.memTotal)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.purple }
                    GradientStop { position: 1; color: Theme.red }
                }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }

    Item {
        width: sys.w; height: 18
        Txt { text: "Load  " + Store.load; size: 12; color: Theme.dim }
        Txt {
            visible: Store.batPresent
            anchors.right: parent.right
            text: Store.batStatus + (Store.batWatts > 0.1 ? (" · " + Store.batWatts.toFixed(1) + " W") : "") + (Store.batTime !== "" ? (" · " + Store.batTime) : "")
            size: 12; color: Theme.cyan
        }
    }

    Chip {
        implicitWidth: sys.w; implicitHeight: 32
        color: hovered ? Theme.hl : Theme.surface
        border.width: 1
        border.color: Theme.border
        Txt { text: "alacritty -e htop"; size: 13; color: Theme.fg }
        onClicked: {
            Store.sysOpen = false
            Store.run("alacritty --config-file " + Store.home + "/.config/alacritty/wm.toml -e htop")
        }
    }
}
