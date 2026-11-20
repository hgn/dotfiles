import QtQuick

// Thin 1px vertical technical separator inside bar panels.
Rectangle {
    width: 1
    height: 16
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: Theme.divider
}
