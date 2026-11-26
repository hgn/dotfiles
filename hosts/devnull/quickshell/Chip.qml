import QtQuick
import Quickshell

// Rounded, hoverable bar element with optional hover tooltip.
Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property int padX: 11
    property bool hovered: mouse.containsMouse
    property color hoverColor: Theme.hl
    property string tooltip: ""
    property bool tooltipAlignRight: true
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth + padX * 2
    implicitHeight: 38
    radius: height / 2
    color: hovered ? hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: 180 } }

    property bool tipShown: false
    Timer {
        id: tipTimer
        interval: 320
        running: root.hovered && root.tooltip !== ""
        onTriggered: root.tipShown = true
    }
    onHoveredChanged: if (!hovered) tipShown = false

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            root.tipShown = false
            root.clicked(m)
        }
        onWheel: w => root.wheel(w)
    }

    LazyLoader {
        active: root.tipShown && root.tooltip !== ""
        PopupWindow {
            id: tipWin
            anchor.item: root
            anchor.rect.x: root.tooltipAlignRight ? root.width : 0
            anchor.rect.y: root.height + 12
            anchor.edges: Edges.Top | Edges.Left
            anchor.gravity: root.tooltipAlignRight ? (Edges.Bottom | Edges.Left) : (Edges.Bottom | Edges.Right)

            readonly property var lines: root.tooltip.split("\n")
            TextMetrics {
                id: tmTitle
                font.family: Theme.font
                font.pixelSize: 15
                font.weight: Font.Bold
                text: tipWin.lines.length > 0 ? tipWin.lines[0] : ""
            }
            TextMetrics {
                id: tmBody
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.Medium
                text: tipWin.lines.length > 1 ? tipWin.lines.slice(1).join("\n") : ""
            }
            readonly property int contentW: Math.min(420, Math.ceil(Math.max(tmTitle.advanceWidth, tmBody.advanceWidth)) + 6)
            implicitWidth: Math.max(170, contentW + 28)
            implicitHeight: tipCol.implicitHeight + 20
            color: "transparent"
            visible: true

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Theme.popup
                border.width: 1
                border.color: Theme.border

                Column {
                    id: tipCol
                    x: 14
                    y: 10
                    width: tipWin.contentW
                    spacing: 4

                    Txt {
                        width: tipCol.width
                        text: tipWin.lines.length > 0 ? tipWin.lines[0] : ""
                        size: 15
                        font.weight: Font.Bold
                        color: Theme.fgBright
                        wrapMode: Text.WordWrap
                    }
                    Txt {
                        width: tipCol.width
                        visible: tipWin.lines.length > 1
                        text: tipWin.lines.length > 1 ? tipWin.lines.slice(1).join("\n") : ""
                        size: 14
                        color: Theme.fg
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
