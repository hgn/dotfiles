import QtQuick
import Quickshell

// Compact technical hoverable bar element (radius 5, crisp highlight + optional tooltip).
Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property int padX: 9
    property bool hovered: mouse.containsMouse
    property color hoverColor: Theme.hl
    property string tooltip: ""
    property bool tooltipAlignRight: true
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth + padX * 2
    implicitHeight: Theme.barHeight - 8
    radius: Theme.chipRadius
    color: hovered ? hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

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
        spacing: 6
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
            anchor.rect.y: root.height + 10
            anchor.edges: Edges.Top | Edges.Left
            anchor.gravity: root.tooltipAlignRight ? (Edges.Bottom | Edges.Left) : (Edges.Bottom | Edges.Right)
            readonly property var lines: root.tooltip.split("\n")
            TextMetrics {
                id: tmTitle
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Bold
                text: tipWin.lines.length > 0 ? tipWin.lines[0] : ""
            }
            TextMetrics {
                id: tmBody
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Medium
                text: tipWin.lines.length > 1 ? tipWin.lines.slice(1).join("\n") : ""
            }
            readonly property int contentW: Math.min(340, Math.ceil(Math.max(tmTitle.advanceWidth, tmBody.advanceWidth)) + 4)
            implicitWidth: Math.max(140, contentW + 24)
            implicitHeight: tipCol.implicitHeight + 16
            color: "transparent"
            visible: true

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.panel
                border.width: 1
                border.color: Theme.borderStrong

                Column {
                    id: tipCol
                    x: 12
                    y: 8
                    width: tipWin.contentW
                    spacing: 3

                    Txt {
                        id: tipTitle
                        width: tipCol.width
                        text: tipWin.lines.length > 0 ? tipWin.lines[0] : ""
                        size: 13
                        font.weight: Font.Bold
                        color: Theme.fgBright
                        wrapMode: Text.WordWrap
                    }
                    Txt {
                        id: tipBody
                        width: tipCol.width
                        visible: tipWin.lines.length > 1
                        text: tipWin.lines.length > 1 ? tipWin.lines.slice(1).join("\n") : ""
                        size: 12
                        color: Theme.fg
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
