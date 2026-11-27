# Host-specific dotfiles for desktop "devnull"

# Wayland compositor & Quickshell / Waybar
link hosts/devnull/hypr                 "$HOME/.config/hypr"
link hosts/devnull/waybar               "$HOME/.config/waybar"
link hosts/devnull/quickshell           "$HOME/.config/quickshell"
link hosts/devnull/fuzzel               "$HOME/.config/fuzzel"

# Terminal override (included by common/kitty.conf via globinclude)
link hosts/devnull/kitty/local.conf     "$HOME/.config/kitty/local.conf"

# GTK & MIME associations
link hosts/devnull/gtk-3.0/settings.ini "$HOME/.config/gtk-3.0/settings.ini"
link hosts/devnull/gtk-4.0/settings.ini "$HOME/.config/gtk-4.0/settings.ini"
link hosts/devnull/gtk-4.0/gtk.css      "$HOME/.config/gtk-4.0/gtk.css"
link hosts/devnull/mimeapps.list        "$HOME/.config/mimeapps.list"

# Host-specific helper scripts
link hosts/devnull/bin/audio-output     "$HOME/.local/bin/audio-output"
link hosts/devnull/bin/linkdrop         "$HOME/.local/bin/linkdrop"

# Background systemd user services/timers (desktop only)
link hosts/devnull/systemd/user/email-sync.service "$HOME/.config/systemd/user/email-sync.service"
link hosts/devnull/systemd/user/email-sync.timer   "$HOME/.config/systemd/user/email-sync.timer"
link hosts/devnull/systemd/user/linkdrop.service   "$HOME/.config/systemd/user/linkdrop.service"
