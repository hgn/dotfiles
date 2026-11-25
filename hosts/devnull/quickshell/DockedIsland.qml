import QtQuick

// Top-docked amethyst glass bar island with concave top fillets and softly
// rounded bottom corners. Set dockLeft / dockRight to attach flush to screen edges.
Item {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool dockLeft: false
    property bool dockRight: false
    property color fill: Theme.glass
    property color edge: Theme.border

    readonly property int leftFlare: dockLeft ? 0 : Theme.barFlare
    readonly property int rightFlare: dockRight ? 0 : Theme.barFlare
    readonly property int padLeft: dockLeft ? 14 : 12
    readonly property int padRight: dockRight ? 14 : 12

    implicitWidth: row.implicitWidth + padLeft + padRight + leftFlare + rightFlare
    implicitHeight: Theme.barHeight

    DockedSurface {
        anchors.fill: parent
        dockLeft: root.dockLeft
        dockRight: root.dockRight
        flare: Theme.barFlare
        radius: Theme.radius
        fillColor: root.fill
        borderColor: root.edge
    }

    Row {
        id: row
        x: root.leftFlare + root.padLeft
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
    }
}
