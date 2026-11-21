import QtQuick

// Top-docked technical glass bar panel with concave top fillets and softly
// rounded bottom corners. Set dockLeft / dockRight to sit flush at screen edges.
Item {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool dockLeft: false
    property bool dockRight: false

    readonly property int leftFlare: dockLeft ? 0 : Theme.barFlare
    readonly property int rightFlare: dockRight ? 0 : Theme.barFlare
    readonly property int padLeft: dockLeft ? 8 : 6
    readonly property int padRight: dockRight ? 8 : 6

    y: Theme.barMarginTop
    implicitWidth: row.implicitWidth + padLeft + padRight + leftFlare + rightFlare
    implicitHeight: Theme.barHeight

    DockedSurface {
        anchors.fill: parent
        dockLeft: root.dockLeft
        dockRight: root.dockRight
        flare: Theme.barFlare
        radius: Theme.radius
        fillColor: Theme.bg
        borderColor: Theme.border
    }

    Row {
        id: row
        x: root.leftFlare + root.padLeft
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
    }
}
