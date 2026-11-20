import QtQuick

// Rounded, hoverable bar element; children are laid out in a row.
Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool hovered: mouse.containsMouse
    property color hoverColor: Theme.hl
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 38
    radius: height / 2
    color: hovered ? hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: 180 } }

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
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w)
    }
}
