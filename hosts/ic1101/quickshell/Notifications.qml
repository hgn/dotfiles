import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Bottom-right concave corner-docked notification stack (replaces mako).
// Matches the concave fillets of the docked top bar panels with translucent
// Tokyo Night amethyst glass, larger typography, and smooth slide/fade motion.
LazyLoader {
    id: loader
    active: Store.notifications.length > 0

    PanelWindow {
        id: win

        screen: {
            const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        }
        anchors { bottom: true; right: true }
        margins.bottom: 14
        margins.right: 0
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 468
        implicitHeight: Math.max(1, stack.implicitHeight + 8)
        color: "transparent"
        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        function iconSrc(n) {
            if (!n) return ""
            for (let c of [n.image, n.appIcon, n.desktopEntry]) {
                if (!c) continue
                if (c.startsWith("image://icon/")) c = c.substring(13)
                if (c.startsWith("/")) return "file://" + c
                if (c.startsWith("file:") || c.startsWith("image:")) return c
                if (Quickshell.hasThemeIcon(c)) return Quickshell.iconPath(c)
            }
            return ""
        }

        ScriptModel {
            id: notifModel
            values: Store.notifications.slice().reverse()
        }

        Column {
            id: stack
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width
            spacing: -2

            move: Transition {
                NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: notifModel

                Item {
                    id: card
                    required property var modelData

                    readonly property bool isLocal: !!modelData.local
                    readonly property var n: modelData.notif
                    readonly property bool isCritical: !isLocal && n && n.urgency === NotificationUrgency.Critical
                    readonly property bool isLow: !isLocal && n && n.urgency === NotificationUrgency.Low
                    readonly property color accent: isLocal ? modelData.accent
                                                  : isCritical ? Theme.red
                                                  : isLow ? "#8f82b8"
                                                  : Theme.purple
                    readonly property string img: isLocal ? "" : win.iconSrc(n)
                    readonly property int fallbackIcon: isLocal ? modelData.iconCode : (isCritical ? 0xF0026 : 0xF009A)
                    readonly property string appTitle: isLocal ? modelData.appName : (n ? (n.appName || "System") : "")
                    readonly property string summaryText: isLocal ? modelData.summary : (n ? n.summary : "")
                    readonly property string bodyText: isLocal ? modelData.body : (n ? n.body : "")

                    readonly property bool closing: Store.notifTick >= 0 && !!modelData.closing
                    readonly property bool paused:  Store.notifTick >= 0 && !!modelData.paused
                    readonly property real remainingMs: Store.notifTick >= 0 ? modelData.remainingMs : modelData.totalMs
                    readonly property real progress: Math.max(0, Math.min(1, remainingMs / Math.max(1, modelData.totalMs)))

                    readonly property real dockFlare: 9
                    readonly property real bodyPadV: 15
                    readonly property real innerH: contentRow.implicitHeight + bodyPadV * 2

                    property bool entered: false
                    Component.onCompleted: entered = true

                    width: stack.width
                    height: innerH + dockFlare * 2

                    opacity: (!entered || closing) ? 0 : 1
                    transform: Translate {
                        x: (!card.entered || card.closing) ? 44 : 0
                        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    // Right-docked amethyst glass surface with concave top/bottom fillets
                    Shape {
                        id: dockShape
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        readonly property real w: Math.max(0, width)
                        readonly property real h: Math.max(0, height)
                        readonly property real f: card.dockFlare
                        readonly property real r: 14
                        readonly property real s: 0.5

                        readonly property string contourSvg: {
                            if (w < 30 || h < 2 * f + 8) return ""
                            const rr = Math.min(r, (h - 2 * f) / 2)
                            return `M ${w - s} 0`
                                 + ` A ${f} ${f} 0 0 1 ${w - f - s} ${f}`
                                 + ` L ${rr + s} ${f}`
                                 + ` A ${rr} ${rr} 0 0 0 ${s} ${f + rr}`
                                 + ` L ${s} ${h - f - rr}`
                                 + ` A ${rr} ${rr} 0 0 0 ${rr + s} ${h - f}`
                                 + ` L ${w - f - s} ${h - f}`
                                 + ` A ${f} ${f} 0 0 1 ${w - s} ${h}`
                        }
                        readonly property string fillSvg: {
                            if (contourSvg === "") return ""
                            return `M ${w} 0 L` + contourSvg.substring(1) + ` L ${w} ${h} Z`
                        }

                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: Qt.rgba(0.118, 0.086, 0.220, 0.46)
                            PathSvg { path: dockShape.fillSvg }
                        }
                        ShapePath {
                            strokeWidth: 1.1
                            strokeColor: card.isCritical
                                         ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, card.paused ? 0.95 : 0.80)
                                         : Qt.rgba(card.accent.r, card.accent.g, card.accent.b, card.paused ? 0.88 : 0.54)
                            fillColor: "transparent"
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: dockShape.contourSvg }
                        }

                        // Subtle countdown progress bar hugging the bottom dock edge
                        Rectangle {
                            x: 16
                            y: dockShape.h - dockShape.f - 2.5
                            height: 2
                            radius: 1
                            width: Math.max(0, (dockShape.w - dockShape.f - 22) * card.progress)
                            color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.78)
                        }
                    }

                    Row {
                        id: contentRow
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.top: parent.top
                        anchors.topMargin: card.dockFlare + card.bodyPadV
                        spacing: 14

                        // Soft circular amethyst icon halo
                        ClippingRectangle {
                            width: 46
                            height: 46
                            radius: 23
                            color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.16)
                            anchors.top: parent.top
                            anchors.topMargin: 2

                            IconImage {
                                id: nImg
                                anchors.fill: parent
                                anchors.margins: 5
                                source: card.img
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Icon {
                                anchors.centerIn: parent
                                code: card.fallbackIcon
                                size: 23
                                color: card.accent
                                visible: nImg.status !== Image.Ready
                            }
                        }

                        Column {
                            width: parent.width - 60
                            spacing: 4

                            Item {
                                width: parent.width
                                height: 20

                                Txt {
                                    anchors.left: parent.left
                                    anchors.right: closeBtn.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: card.appTitle
                                    font.family: "Inter"
                                    size: 12
                                    font.weight: Font.SemiBold
                                    color: card.accent
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1.1
                                    elide: Text.ElideRight
                                }
                                Txt {
                                    id: closeBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "×"
                                    font.family: "Inter"
                                    size: 18
                                    font.weight: Font.Normal
                                    color: Theme.dim
                                    opacity: card.paused ? 0.95 : 0.35
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }

                            Txt {
                                width: parent.width
                                text: card.summaryText
                                font.family: "Inter Display"
                                size: 19
                                font.weight: Font.SemiBold
                                color: Theme.fgBright
                                wrapMode: Text.WordWrap
                                lineHeight: 1.15
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Txt {
                                width: parent.width
                                visible: text !== ""
                                text: card.bodyText
                                textFormat: Text.StyledText
                                font.family: "Inter"
                                size: 15
                                font.weight: Font.Normal
                                color: Qt.rgba(0.84, 0.87, 0.98, 0.90)
                                wrapMode: Text.WordWrap
                                lineHeight: 1.30
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: 8
                                topPadding: 6
                                visible: actRep.count > 0
                                Repeater {
                                    id: actRep
                                    model: card.n ? card.n.actions.filter(a => a.identifier !== "default") : []
                                    Chip {
                                        id: actBtn
                                        required property var modelData
                                        implicitHeight: 32
                                        padX: 11
                                        color: hovered ? card.accent : Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.16)
                                        border.width: 1
                                        border.color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.45)
                                        Txt {
                                            text: actBtn.modelData ? actBtn.modelData.text : ""
                                            font.family: "Inter"
                                            size: 14
                                            font.weight: Font.Medium
                                            color: actBtn.hovered ? Theme.bgSolid : Theme.fgBright
                                        }
                                        onClicked: {
                                            actBtn.modelData.invoke()
                                            Store.dismissNotif(card.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: Store.setNotifPaused(card.modelData.id, true)
                        onExited:  Store.setNotifPaused(card.modelData.id, false)
                        onClicked: m => {
                            if (m.button === Qt.RightButton) Store.dismissNotif(card.modelData.id)
                            else Store.activateNotif(card.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
