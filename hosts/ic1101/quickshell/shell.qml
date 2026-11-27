//@ pragma UseQApplication
// Quickshell desktop shell for laptop "ic1101" (Hyprland, Tokyo Night technical style).
// Replaces waybar, mako, fuzzel (app launcher) and wlogout.
// IPC: qs ipc call shell launcher|power|mixer|sys|dismiss|dnd|refreshVpn|status
//      qs ipc call shell bar show|hide|toggle
import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Notifications {}
    WorkspaceHud {}
    Launcher {}
    PowerMenu {}
}
