# Common dotfiles (shared across all hosts: CLI, editors, scripts, shared WM helpers)

link common/bin                         "$HOME/bin"
link common/zshrc                       "$HOME/.zshrc"
link common/dircolors                   "$HOME/.dircolors"
link common/gitconfig                   "$HOME/.gitconfig"
link common/reportbugrc                 "$HOME/.reportbugrc"
link common/screenrc                    "$HOME/.screenrc"
link common/tmux.conf                   "$HOME/.tmux.conf"
link common/irssi                       "$HOME/.irssi"
link common/mailcap                     "$HOME/.mailcap"

# Vim & Neovim
link common/vimrc                       "$HOME/.vimrc"
link common/vimdata                     "$HOME/.vim"
link common/init.lua                    "$HOME/.config/nvim/init.lua"
ensure_dir                              "$HOME/.local/share/nvim/undo"

# GnuPG
ensure_dir                              "$HOME/.gnupg" 700
link common/gpg-agent.conf              "$HOME/.gnupg/gpg-agent.conf"

# Shared tools & terminal base
link common/kitty.conf                  "$HOME/.config/kitty/kitty.conf"
link common/imv                         "$HOME/.config/imv"
link common/inkscape-cp-flatuicolors.gpl "$HOME/.config/inkscape/palettes/inkscape-cp-flatuicolors.gpl"

# Shared Wayland WM helper scripts & assets
link common/wm/bin                      "$HOME/.local/share/wm/bin"
link common/wm/wlogout                  "$HOME/.local/share/wm/wlogout"
link common/wm/wallpapers/synthwave_4k_purple.jpg "$HOME/.local/share/wm/wallpaper"
