import QtQuick

// Technical linear slider (0..1). Drag, click or scroll; emits moved(v).
Item {
    id: root
    property real value: 0
    property real step: 0.05
    property int thickness: 5
    property color from: Theme.blue
    property color to: Theme.purple
    readonly property bool active: mouse.pressed || mouse.containsMouse
    signal moved(real v)

    implicitWidth: 200
    implicitHeight: 20

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.active ? root.thickness + 2 : root.thickness
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.12)
        Behavior on height { NumberAnimation { duration: 120 } }

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: Math.max(0, parent.width * root.clamp(root.value))
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.from }
                GradientStop { position: 1; color: root.to }
            }
            Behavior on width {
                enabled: !mouse.pressed
                NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        width: root.active ? 12 : 8
        height: root.active ? 16 : 12
        radius: 3
        color: Theme.fgBright
        border.width: 1
        border.color: root.to
        anchors.verticalCenter: parent.verticalCenter
        x: root.clamp(root.value) * (root.width - width)
        Behavior on width { NumberAnimation { duration: 120 } }
        Behavior on height { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function apply(mx) { root.moved(root.clamp((mx - 4) / root.width)) }
        onPressed: m => apply(m.x)
        onPositionChanged: m => { if (pressed) apply(m.x) }
        onWheel: w => root.moved(root.clamp(root.value + (w.angleDelta.y > 0 ? root.step : -root.step)))
    }
}
