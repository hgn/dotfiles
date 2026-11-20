import QtQuick

// Floating technical glass bar island (matches ic1101 waybar aesthetic).
Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing

    y: Theme.barMarginTop
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: Theme.border

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2
    }
}
