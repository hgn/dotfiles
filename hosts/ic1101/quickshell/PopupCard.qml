import QtQuick
import Quickshell
import Quickshell.Hyprland

// Technical dropdown popup hanging below a bar element.
PopupWindow {
    id: root
    required property Item anchorItem
    required property var barWindow
    property bool open: false
    property bool alignRight: true
    signal dismissed()
    default property alias content: body.data

    anchor.item: anchorItem
    anchor.rect.x: alignRight ? anchorItem.width : 0
    anchor.rect.y: anchorItem.height + 12
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: alignRight ? (Edges.Bottom | Edges.Left) : (Edges.Bottom | Edges.Right)
    implicitWidth: body.implicitWidth + 32
    implicitHeight: body.implicitHeight + 28
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
        radius: Theme.cardRadius
        color: Theme.panel
        border.width: 1
        border.color: Theme.borderStrong
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        transformOrigin: root.alignRight ? Item.TopRight : Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Column {
            id: body
            x: 16
            y: 14
            spacing: 12
        }
    }
}
