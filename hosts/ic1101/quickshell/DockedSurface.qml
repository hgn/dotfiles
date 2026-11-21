import QtQuick
import QtQuick.Shapes

// Top-docked glass panel surface with concave fillets curving smoothly into
// the upper horizontal screen edge and softly rounded bottom corners.
// Set dockLeft / dockRight to attach seamlessly to the left or right monitor edge.
Shape {
    id: root

    property bool dockLeft: false
    property bool dockRight: false
    property real flare: Theme.barFlare
    property real radius: Theme.radius
    property color fillColor: Theme.bg
    property color borderColor: Theme.border
    property real borderWidth: 1

    preferredRendererType: Shape.CurveRenderer

    readonly property real w: Math.max(0, width)
    readonly property real h: Math.max(0, height)
    readonly property real s: borderWidth * 0.5
    readonly property real fL: dockLeft  ? 0 : Math.min(flare, w / 2, Math.max(0, h - 2))
    readonly property real fR: dockRight ? 0 : Math.min(flare, w / 2, Math.max(0, h - 2))
    readonly property real bodyW: Math.max(0, w - fL - fR - (dockLeft ? 0 : s) - (dockRight ? 0 : s))
    readonly property real rL: dockLeft  ? 0 : Math.min(radius, bodyW / 2, Math.max(0, h - fL - 2 * s))
    readonly property real rR: dockRight ? 0 : Math.min(radius, bodyW / 2, Math.max(0, h - fR - 2 * s))

    readonly property string contourSvg: {
        if (w < 4 || h < 4) return ""
        const xL = fL + s
        const xR = w - fR - s
        const yB = h - s
        let d = ""

        if (dockLeft) {
            d += `M 0 ${yB}`
        } else {
            d += `M 0 ${s} L ${s} ${s}`
            if (fL > 0) d += ` A ${fL} ${fL} 0 0 1 ${xL} ${fL + s}`
            d += ` L ${xL} ${yB - rL}`
            if (rL > 0) d += ` A ${rL} ${rL} 0 0 0 ${xL + rL} ${yB}`
        }

        if (dockRight) {
            d += ` L ${w} ${yB}`
        } else {
            d += ` L ${xR - rR} ${yB}`
            if (rR > 0) d += ` A ${rR} ${rR} 0 0 0 ${xR} ${yB - rR}`
            d += ` L ${xR} ${fR + s}`
            if (fR > 0) d += ` A ${fR} ${fR} 0 0 1 ${w - s} ${s}`
            d += ` L ${w} ${s}`
        }
        return d
    }

    readonly property string fillSvg: {
        if (contourSvg === "") return ""
        // Replace initial "M ..." with "L ..." after starting at (0, 0) so the fill
        // reaches cleanly to the top edge (y = 0) and any docked side edge.
        const body = "L" + contourSvg.substring(1)
        return `M 0 0 ${body} L ${w} 0 Z`
    }

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
        PathSvg { path: root.fillSvg }
    }

    ShapePath {
        strokeWidth: root.borderWidth
        strokeColor: root.borderColor
        fillColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.FlatCap
        PathSvg { path: root.contourSvg }
    }
}
