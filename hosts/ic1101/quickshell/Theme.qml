pragma Singleton
import QtQuick
import Quickshell

// Tokyo Night technical palette & compact metrics for ic1101 (2160x1350).
Singleton {
    readonly property color bg:           Qt.rgba(0.102, 0.106, 0.149, 0.78) // #1a1b26 @ 78%
    readonly property color bgSolid:      "#1a1b26"
    readonly property color panel:        Qt.rgba(0.078, 0.082, 0.118, 0.94) // popups / overlays
    readonly property color surface:      Qt.rgba(0.125, 0.133, 0.188, 0.85) // subtle inner cards
    readonly property color hl:           "#292e42"
    readonly property color border:       Qt.rgba(0.478, 0.635, 0.969, 0.30) // blue @ 30%
    readonly property color borderStrong: Qt.rgba(0.478, 0.635, 0.969, 0.55)
    readonly property color divider:      Qt.rgba(0.337, 0.373, 0.537, 0.45) // dim @ 45%

    readonly property color fg:           "#c0caf5"
    readonly property color fgBright:     "#e0e6ff"
    readonly property color dim:          "#565f89"
    readonly property color blue:         "#7aa2f7"
    readonly property color cyan:         "#7dcfff"
    readonly property color purple:       "#bb9af7"
    readonly property color green:        "#9ece6a"
    readonly property color yellow:       "#e0af68"
    readonly property color orange:       "#ff9e64"
    readonly property color red:          "#f7768e"

    readonly property string font:        "JetBrainsMono Nerd Font"
    readonly property string iconFont:    "Symbols Nerd Font"
    readonly property int fontSize:       17
    readonly property int barHeight:      40
    readonly property int barMarginTop:   0
    readonly property int barMarginX:     12
    readonly property int barFlare:       3
    readonly property int radius:         5
    readonly property int chipRadius:     5
    readonly property int cardRadius:     8

    function ic(cp) { return String.fromCodePoint(cp) }
}
