import QtQuick

// Line graph of values 0..1, newest on the right, `slots` samples wide.
Canvas {
    id: root
    property var values: []
    property int slots: 60
    property color stroke: Theme.blue
    property real lineWidth: 2

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = values.length
        if (n < 2)
            return
        const w = width, h = height
        const step = w / (slots - 1)
        const px = i => w - (n - 1 - i) * step
        const py = v => h - Math.max(0, Math.min(1, v)) * (h - lineWidth) - lineWidth / 2
        ctx.beginPath()
        for (let i = 0; i < n; i++) {
            if (i === 0) ctx.moveTo(px(i), py(values[i]))
            else ctx.lineTo(px(i), py(values[i]))
        }
        ctx.lineWidth = lineWidth
        ctx.lineJoin = "round"
        ctx.strokeStyle = stroke
        ctx.stroke()
        ctx.lineTo(px(n - 1), h)
        ctx.lineTo(px(0), h)
        ctx.closePath()
        const g = ctx.createLinearGradient(0, 0, 0, h)
        g.addColorStop(0, Qt.rgba(stroke.r, stroke.g, stroke.b, 0.40))
        g.addColorStop(1, Qt.rgba(stroke.r, stroke.g, stroke.b, 0.0))
        ctx.fillStyle = g
        ctx.fill()
    }
}
