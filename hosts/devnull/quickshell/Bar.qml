import QtQuick
import Quickshell
import Quickshell.Wayland

// One per screen. The window is taller than the bar so the island can grow
// downwards; only the islands take input, the rest is click-through
// (except while the launcher is open, see below).
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    // while the launcher is open the surface covers the screen, so a click
    // anywhere outside it can close it (a HyprlandFocusGrab cleared at once
    // next to exclusive keyboard focus)
    implicitHeight: Store.launcherOpen ? screen.height : 640
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    // the launcher needs the keyboard while it is open, nothing else does
    WlrLayershell.keyboardFocus: Store.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        regions: Store.launcherOpen ? [fullRegion] : islandRegions
    }
    Region { id: fullRegion; item: dismissArea }
    property list<Region> islandRegions: [
        Region { item: left },
        Region { item: island },
        Region { item: right }
    ]

    // catches the click next to the open launcher
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        enabled: Store.launcherOpen
        onClicked: Store.launcherOpen = false
    }

    IdleInhibitor {
        window: bar
        enabled: Store.inhibitIdle
    }

    LeftIsland {
        id: left
        x: 0
        dockLeft: true
    }

    Island {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
    }

    RightIsland {
        id: right
        anchors.right: parent.right
        dockRight: true
        barWindow: bar
    }
}
