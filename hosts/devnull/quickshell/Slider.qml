import QtQuick

// Value 0..1. Drag, click or scroll; emits moved(v) and leaves the binding
// of `value` to the caller.
Item {
    id: root
    property real value: 0
    property real step: 0.02
    property int thickness: 8
    property color from: Theme.blue
    property color to: Theme.purple
    readonly property bool active: mouse.pressed || mouse.containsMouse
    signal moved(real v)

    implicitWidth: 220
    implicitHeight: 24

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.active ? root.thickness + 4 : root.thickness
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.12)
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: Math.max(height, parent.width * root.clamp(root.value))
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.from }
                GradientStop { position: 1; color: root.to }
            }
            Behavior on width {
                enabled: !mouse.pressed
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        width: root.active ? 20 : 14
        height: width
        radius: width / 2
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        x: root.clamp(root.value) * (root.width - width)
        Behavior on width { NumberAnimation { duration: 150 } }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 10
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Qt.rgba(root.to.r, root.to.g, root.to.b, root.active ? 0.45 : 0)
            border.width: 3
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function apply(mx) { root.moved(root.clamp((mx - 6) / root.width)) }
        onPressed: m => apply(m.x)
        onPositionChanged: m => { if (pressed) apply(m.x) }
        onWheel: w => root.moved(root.clamp(root.value + (w.angleDelta.y > 0 ? root.step : -root.step)))
    }
}
