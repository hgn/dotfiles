import QtQuick

// Subtle vertical amethyst separator between logical groups in the top bar.
Rectangle {
    width: 1
    height: 22
    anchors.verticalCenter: parent.verticalCenter
    color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.28)
}
