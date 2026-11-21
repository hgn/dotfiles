import QtQuick
import Quickshell
import Quickshell.Wayland

// Floating 3-panel technical top bar (one per screen) + center OSD banner.
// Click-through everywhere except the visible panels and OSD.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barMarginTop + 230
    exclusiveZone: Store.barHidden ? 0 : Theme.barMarginTop + Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property list<Region> barRegions: [
        Region { item: left },
        Region { item: center },
        Region { item: right }
    ]
    property list<Region> barAndOsdRegions: [
        Region { item: left },
        Region { item: center },
        Region { item: right },
        Region { item: osd }
    ]
    property list<Region> osdOnlyRegions: [
        Region { item: osd }
    ]
    property list<Region> emptyRegions: []

    mask: Region {
        regions: Store.barHidden
                 ? (osd.shown ? bar.osdOnlyRegions : bar.emptyRegions)
                 : (osd.shown ? bar.barAndOsdRegions : bar.barRegions)
    }

    IdleInhibitor {
        window: bar
        enabled: Store.inhibitIdle
    }

    LeftPanel {
        id: left
        x: 0
        visible: !Store.barHidden
    }

    CenterPanel {
        id: center
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !Store.barHidden
    }

    RightPanel {
        id: right
        anchors.right: parent.right
        barWindow: bar
        visible: !Store.barHidden
    }

    OsdBanner {
        id: osd
        anchors.horizontalCenter: parent.horizontalCenter
        y: Store.barHidden ? 10 : center.y + center.height + 8
    }
}
