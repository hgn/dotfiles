import QtQuick
import Quickshell

// CPU and temperature history, memory, load.
PopupCard {
    id: sys
    open: Store.sysOpen
    onDismissed: Store.sysOpen = false

    readonly property int w: 460

    component Stat: Column {
        property alias label: lbl.text
        property alias value: val.text
        property color tint: Theme.fg
        spacing: 2
        Txt { id: lbl; size: 12; color: Theme.dim; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.5 }
        Txt { id: val; size: 26; font.weight: Font.Bold; color: parent.tint }
    }

    Txt { text: "System"; size: 21; font.weight: Font.Bold; color: "white" }

    Row {
        spacing: 34
        Stat { label: "CPU"; value: Math.round(Store.cpu * 100) + "%"; tint: Theme.blue }
        Stat { label: "Temperatur"; value: Math.round(Store.temp) + " °C"; tint: Store.temp > 85 ? Theme.red : Theme.yellow }
        Stat { label: "Last"; value: Store.load.split("  ")[0] || "-"; tint: Theme.cyan }
    }

    Rectangle {
        width: sys.w; height: 130; radius: 16
        color: Qt.rgba(1, 1, 1, 0.04)
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
            anchors.fill: parent
            anchors.margins: 8
            values: Store.tempHistory
            stroke: Theme.yellow
            lineWidth: 1.5
        }
        Spark {
            anchors.fill: parent
            anchors.margins: 8
            values: Store.cpuHistory
            stroke: Theme.blue
            lineWidth: 2.5
        }
        Txt {
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
            text: "CPU  ·  Temperatur  ·  3 min"; size: 11; color: Theme.dim
        }
    }

    Column {
        spacing: 8
        Item {
            width: sys.w; height: 20
            Txt { text: "Arbeitsspeicher"; size: 14; color: Theme.dim }
            Txt {
                anchors.right: parent.right
                text: Store.memUsed.toFixed(1) + " / " + Store.memTotal.toFixed(0) + " GiB"
                size: 14; color: Theme.purple
            }
        }
        Rectangle {
            width: sys.w; height: 10; radius: 5
            color: Qt.rgba(1, 1, 1, 0.10)
            Rectangle {
                height: parent.height; radius: 5
                width: parent.width * Math.min(1, Store.memUsed / Store.memTotal)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.purple }
                    GradientStop { position: 1; color: Theme.red }
                }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    Txt { text: "Load  " + Store.load; size: 14; color: Theme.dim }

    Row {
        spacing: 10
        Chip {
            implicitWidth: (sys.w - 10) / 2; implicitHeight: 40
            color: hovered ? Theme.hl : Qt.rgba(1, 1, 1, 0.05)
            Txt { text: "htop"; size: 15 }
            onClicked: { Store.sysOpen = false; Store.run("kitty -e htop") }
        }
        Chip {
            implicitWidth: (sys.w - 10) / 2; implicitHeight: 40
            color: hovered ? Theme.hl : Qt.rgba(1, 1, 1, 0.05)
            Txt { text: "Systemüberwachung"; size: 15 }
            onClicked: { Store.sysOpen = false; Store.run("gnome-system-monitor") }
        }
    }
}
