# Host-specific dotfiles for laptop "ic1101"

# Wayland compositor & Quickshell desktop shell (Tokyo Night technical style)
link hosts/ic1101/hypr                  "$HOME/.config/hypr"
link hosts/ic1101/quickshell            "$HOME/.config/quickshell"
link hosts/ic1101/fuzzel                "$HOME/.config/fuzzel"

# Alacritty base + Hyprland workspace themes
link hosts/ic1101/alacritty             "$HOME/.config/alacritty"

# GTK-3 / GTK-4 Tokyo Night dark styling & MIME defaults
link hosts/ic1101/gtk-3.0/settings.ini  "$HOME/.config/gtk-3.0/settings.ini"
link hosts/ic1101/gtk-4.0/settings.ini  "$HOME/.config/gtk-4.0/settings.ini"
link hosts/ic1101/gtk-4.0/gtk.css       "$HOME/.config/gtk-4.0/gtk.css"
link hosts/ic1101/mimeapps.list         "$HOME/.config/mimeapps.list"

# Background email-sync systemd user timer
link hosts/ic1101/systemd/user/email-sync.service "$HOME/.config/systemd/user/email-sync.service"
link hosts/ic1101/systemd/user/email-sync.timer   "$HOME/.config/systemd/user/email-sync.timer"

# Hardware / kernel module overrides (installed only with --system)
system_file hosts/ic1101/etc/modprobe.d/module-blacklist.conf /etc/modprobe.d/module-blacklist.conf
system_file hosts/ic1101/etc/modprobe.d/iwlwifi.conf          /etc/modprobe.d/iwlwifi.conf
