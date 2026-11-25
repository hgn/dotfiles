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
    implicitHeight: 260
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        regions: islandRegions
    }
    property list<Region> islandRegions: [
        Region { item: left },
        Region { item: island },
        Region { item: right }
    ]

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
