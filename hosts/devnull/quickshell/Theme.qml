pragma Singleton
import QtQuick
import Quickshell

// Tokyo Night palette and metrics shared by every component.
Singleton {
    readonly property color island: Qt.rgba(0.065, 0.062, 0.105, 0.92)
    readonly property color bgSolid: "#1a1b26"
    readonly property color glass: Qt.rgba(0.118, 0.086, 0.220, 0.56)
    readonly property color popup: Qt.rgba(0.06, 0.06, 0.09, 0.96)
    readonly property color hl: Qt.rgba(0.255, 0.28, 0.41, 0.50)
    readonly property color border: Qt.rgba(0.733, 0.604, 0.969, 0.36)
    readonly property color fg: "#c0caf5"
    readonly property color fgBright: "#e0e6ff"
    readonly property color dim: "#565f89"
    readonly property color blue: "#7aa2f7"
    readonly property color cyan: "#7dcfff"
    readonly property color purple: "#bb9af7"
    readonly property color green: "#9ece6a"
    readonly property color yellow: "#e0af68"
    readonly property color red: "#f7768e"

    readonly property string font: "Inter"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontSize: 17
    readonly property int barHeight: 50
    readonly property int barFlare: 8
    readonly property int radius: 14

    // icons are written as code points: the Nerd Font private-use glyphs do
    // not survive every editor and tool
    function ic(cp) { return String.fromCodePoint(cp) }
}
