import QtQuick

Text {
    property int size: Theme.fontSize
    font.family: Theme.font
    font.pixelSize: size
    font.weight: Font.Medium
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
