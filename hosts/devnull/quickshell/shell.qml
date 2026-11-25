//@ pragma UseQApplication
// Quickshell desktop shell for "devnull": top bar with a dynamic island,
// notifications, volume mixer, system popup. Replaces waybar and mako here.
// IPC: qs ipc call shell dismiss|dnd|mixer|sys|launcher
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
