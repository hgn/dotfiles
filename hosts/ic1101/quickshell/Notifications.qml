import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Technical top-right notification stack (replaces mako).
// Only creates a layer-shell surface while notifications are active.
LazyLoader {
    id: loader
    active: Store.notifications.length > 0

    PanelWindow {
        id: win

        screen: {
            const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        }
        anchors { top: true; right: true }
        margins.top: Store.barHidden ? Theme.barMarginTop : Theme.barMarginTop + Theme.barHeight + 10
        margins.right: Theme.barMarginX
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 380
        implicitHeight: Math.max(1, stack.implicitHeight)
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

        Column {
            id: stack
            width: parent.width
            spacing: 8

            Repeater {
                model: Store.notifications

                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var n: modelData.notif
                    readonly property bool isCritical: n && n.urgency === NotificationUrgency.Critical
                    readonly property bool isLow: n && n.urgency === NotificationUrgency.Low
                    readonly property color accent: isCritical ? Theme.red : isLow ? Theme.dim : Theme.blue
                    readonly property string img: win.iconSrc(n)

                    width: stack.width
                    height: bodyRow.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.panel
                    border.width: 1
                    border.color: isCritical ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.70) : Theme.borderStrong
                    clip: true

                    // Crisp 3px left urgency strip
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: card.accent
                    }

                    // Thin 2px countdown progress bar at the bottom
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.bottom: parent.bottom
                        height: 2
                        width: Math.max(0, (parent.width - 3) * (card.modelData.remainingMs / Math.max(1, card.modelData.totalMs)))
                        color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.65)
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }

                    Row {
                        id: bodyRow
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        spacing: 10

                        // Icon box
                        ClippingRectangle {
                            width: 38; height: 38
                            radius: Theme.chipRadius
                            color: Theme.surface
                            anchors.top: parent.top
                            anchors.topMargin: 2

                            IconImage {
                                id: nImg
                                anchors.fill: parent
                                anchors.margins: 4
                                source: card.img
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Icon {
                                anchors.centerIn: parent
                                code: card.isCritical ? 0xF0026 : 0xF009A
                                size: 20
                                color: card.accent
                                visible: nImg.status !== Image.Ready
                            }
                        }

                        Column {
                            width: parent.width - 48
                            spacing: 3

                            Item {
                                width: parent.width
                                height: 16
                                Txt {
                                    anchors.left: parent.left
                                    anchors.right: closeBtn.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: card.n ? (card.n.appName || "System") : ""
                                    size: 11
                                    color: card.accent
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1
                                }
                                Txt {
                                    id: closeBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "×"
                                    size: 14
                                    color: Theme.dim
                                }
                            }

                            Txt {
                                width: parent.width
                                text: card.n ? card.n.summary : ""
                                size: 14
                                font.weight: Font.Bold
                                color: Theme.fgBright
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }

                            Txt {
                                width: parent.width
                                visible: text !== ""
                                text: card.n ? card.n.body : ""
                                textFormat: Text.StyledText
                                size: 13
                                color: Theme.fg
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                            }

                            Row {
                                spacing: 6
                                topPadding: 4
                                visible: actRep.count > 0
                                Repeater {
                                    id: actRep
                                    model: card.n ? card.n.actions.filter(a => a.identifier !== "default") : []
                                    Chip {
                                        id: actBtn
                                        required property var modelData
                                        implicitHeight: 24
                                        padX: 8
                                        color: hovered ? Theme.blue : Theme.surface
                                        border.width: 1
                                        border.color: Theme.border
                                        Txt {
                                            text: actBtn.modelData ? actBtn.modelData.text : ""
                                            size: 12
                                            color: actBtn.hovered ? Theme.bgSolid : Theme.fg
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
