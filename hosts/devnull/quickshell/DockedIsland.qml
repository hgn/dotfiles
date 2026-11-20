import QtQuick

// Island hanging from the top edge: the background starts above the screen,
// so the top corners are cut off and only the bottom ones are round.
Item {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property color fill: Theme.glass
    property color edge: Theme.border

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 6

    Rectangle {
        x: 3
        y: -Theme.radius
        width: parent.width - 6
        height: parent.height + Theme.radius + 5
        radius: Theme.radius
        color: Qt.rgba(0, 0, 0, 0.20)
    }
    Rectangle {
        y: -Theme.radius
        width: parent.width
        height: parent.height + Theme.radius
        radius: Theme.radius
        color: root.fill
        border.color: root.edge
        border.width: 1
    }
    Row {
        id: row
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        spacing: 4
    }
}
