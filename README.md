# dotfiles

Persönliche Konfigurationen, aufgeteilt in gemeinsame CLI-/Editor-Configs (`common/`) und host-spezifische Desktop-/Laptop-Setups (`hosts/<hostname>/`).

## Struktur

```text
~/.dotfiles/
├── install.sh           # Idempotentes Setup-Skript (host-basiert)
├── common/              # Übergreifend: zsh, nvim, vim, git, tmux, bin/, kitty.conf, wm/
│   └── links.sh
└── hosts/
    ├── ic1101/          # Laptop: Hyprland, Quickshell, Fuzzel (dmenu), Alacritty, modprobe.d
    │   └── links.sh
    └── devnull/         # Desktop: Hyprland (4K), Quickshell, Waybar, GTK, kitty local.conf, bin/
        └── links.sh
```

Private Konfigurationen (z. B. Mail, Credentials) liegen separat in `~/.dotfiles-private`.

## Installation

```sh
git clone https://github.com/hgn/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh --dry-run   # Vorschau
~/.dotfiles/install.sh             # Symlinks anlegen / aktualisieren
```

### Optionen

- `-n, --dry-run` — zeigt geplante Änderungen ohne zu schreiben
- `--host <name>` — überschreibt den erkannten Hostnamen (`/etc/hostname`)
- `--common-only` — verlinkt nur `common/` (z. B. für Server/VMs)
- `--system` — installiert zusätzlich `hosts/<hostname>/etc/*` per `sudo`
- `--backup` — sichert kollidierende echte Dateien/Verzeichnisse als `*.bak.<timestamp>`

Veraltete Symlinks, die noch auf alte Pfade in `~/.dotfiles/` zeigen, werden automatisch umgehängt; verwaiste Symlinks auf entfernte Dotfiles werden bereinigt.
