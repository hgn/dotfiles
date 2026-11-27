import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history popup backed by cliphist (scaled for ic1101 2160x1350).
// Left-click copies entry back into Wayland clipboard; right-click or × removes it.
PopupCard {
    id: clip
    open: Store.clipOpen
    onDismissed: Store.clipOpen = false

    readonly property int w: 520
    property var entries: []     // [{ id, preview, raw }]

    function refresh() { listProc.running = true }

    onOpenChanged: if (open) refresh()

    Process {
        id: listProc
        command: ["sh", "-c", "cliphist list | head -n 30"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    if (!line) continue
                    const tab = line.indexOf("\t")
                    if (tab < 0) continue
                    const id = line.slice(0, tab)
                    const preview = line.slice(tab + 1).replace(/\s+/g, " ").trim()
                    out.push({ id: id, preview: preview || "(leer)", raw: line })
                }
                clip.entries = out
            }
        }
    }

    function selectEntry(id) {
        Store.run("printf '%s\\t\\n' " + JSON.stringify(id) + " | cliphist decode | wl-copy")
        Store.clipOpen = false
    }

    function deleteEntry(id) {
        Store.run("printf '%s\\t\\n' " + JSON.stringify(id) + " | cliphist delete")
        clip.entries = clip.entries.filter(e => e.id !== id)
    }

    function wipeAll() {
        Store.run("cliphist wipe")
        clip.entries = []
    }

    // Header
    Item {
        width: clip.w
        height: 30

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9
            Icon { code: 0xF014C; size: 20; color: Theme.purple }
            Txt { text: "Zwischenablage"; size: 17; font.weight: Font.Bold; color: Theme.fgBright }
            Txt {
                visible: clip.entries.length > 0
                text: "(" + clip.entries.length + ")"
                size: 13
                color: Theme.dim
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Chip {
                implicitHeight: 28
                padX: 10
                color: hovered ? Theme.hl : Qt.rgba(1, 1, 1, 0.05)
                Txt { text: "Fuzzel"; size: 13; color: Theme.fg }
                onClicked: {
                    Store.clipOpen = false
                    Store.run("cliphist list | fuzzel --dmenu --prompt '󰅌  Clipboard › ' | cliphist decode | wl-copy")
                }
            }
            Chip {
                implicitHeight: 28
                padX: 10
                visible: clip.entries.length > 0
                hoverColor: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25)
                color: hovered ? hoverColor : Qt.rgba(1, 1, 1, 0.05)
                Txt { text: "Leeren"; size: 13; color: Theme.red }
                onClicked: clip.wipeAll()
            }
        }
    }

    // Entry list
    ListView {
        id: list
        width: clip.w
        height: Math.min(460, Math.max(76, clip.entries.length * 42))
        clip: true
        spacing: 4
        model: clip.entries
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            width: list.width
            height: 38
            radius: Theme.chipRadius + 2
            color: rowMouse.containsMouse ? Theme.hl : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: rowMouse.containsMouse
                          ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)
                          : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Txt {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: delBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.preview
                size: 14
                color: rowMouse.containsMouse ? Theme.fgBright : Theme.fg
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => {
                    if (m.button === Qt.RightButton) clip.deleteEntry(row.modelData.id)
                    else clip.selectEntry(row.modelData.id)
                }
            }

            Item {
                id: delBtn
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                opacity: rowMouse.containsMouse ? 0.9 : 0.35

                Txt {
                    anchors.centerIn: parent
                    text: "×"
                    size: 16
                    color: delMouse.containsMouse ? Theme.red : Theme.dim
                }
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clip.deleteEntry(row.modelData.id)
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            visible: clip.entries.length === 0
            text: "Zwischenablage ist leer"
            size: 14
            color: Theme.dim
        }
    }

    Txt {
        text: "Linksklick: kopieren   ·   Rechtsklick: entfernen   ·   Super+C: Suche"
        size: 12
        color: Theme.dim
    }
}
