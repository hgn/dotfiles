pragma Singleton
import QtQuick
import Quickshell

// Tokyo Night palette and metrics shared by every component.
Singleton {
    readonly property color island: "#08080c"
    readonly property color glass: Qt.rgba(0.10, 0.105, 0.15, 0.82)
    readonly property color popup: Qt.rgba(0.06, 0.06, 0.09, 0.96)
    readonly property color hl: Qt.rgba(0.255, 0.28, 0.41, 0.50)
    readonly property color border: Qt.rgba(0.48, 0.64, 0.97, 0.20)
    readonly property color fg: "#c0caf5"
    readonly property color dim: "#565f89"
    readonly property color blue: "#7aa2f7"
    readonly property color cyan: "#7dcfff"
    readonly property color purple: "#bb9af7"
    readonly property color green: "#9ece6a"
    readonly property color yellow: "#e0af68"
    readonly property color red: "#f7768e"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontSize: 17
    readonly property int barHeight: 54
    readonly property int radius: 22

    // icons are written as code points: the Nerd Font private-use glyphs do
    // not survive every editor and tool
    function ic(cp) { return String.fromCodePoint(cp) }
}
