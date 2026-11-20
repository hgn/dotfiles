import QtQuick

// Compact technical hoverable bar element (radius 5, crisp highlight).
Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property int padX: 9
    property bool hovered: mouse.containsMouse
    property color hoverColor: Theme.hl
    property string tooltip: ""
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth + padX * 2
    implicitHeight: Theme.barHeight - 8
    radius: Theme.chipRadius
    color: hovered ? hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

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
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w)
    }
}
