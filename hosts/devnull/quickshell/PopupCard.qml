import QtQuick
import Quickshell
import Quickshell.Hyprland

// Popup hanging below a bar element, right-aligned to it. Closes on a click
// outside (the bar itself does not count, so its toggle keeps working).
PopupWindow {
    id: root
    required property Item anchorItem
    required property var barWindow
    property bool open: false
    signal dismissed()
    default property alias content: body.data

    anchor.item: anchorItem
    anchor.rect.x: anchorItem.width
    anchor.rect.y: anchorItem.height + 16
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Left
    implicitWidth: body.implicitWidth + 44
    implicitHeight: body.implicitHeight + 40
    color: "transparent"
    visible: open || card.opacity > 0

    HyprlandFocusGrab {
        active: root.open
        windows: [root, root.barWindow]
        onCleared: root.dismissed()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 26
        color: Theme.popup
        border.width: 1
        border.color: Theme.border
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

        Column {
            id: body
            x: 22
            y: 20
            spacing: 14
        }
    }
}
