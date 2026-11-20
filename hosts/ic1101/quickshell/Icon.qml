import QtQuick

Text {
    property int code: 0
    property int size: Theme.fontSize + 2
    text: Theme.ic(code)
    font.family: Theme.iconFont
    font.pixelSize: size
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    Behavior on color { ColorAnimation { duration: 180 } }
}
