#!/bin/sh

dotdir=$(pwd)

create()
{
	if test -f $2 || test -d $2
	then
		echo "$2 already exist, I skip this"
	else
		ln -s $dotdir/$1 $2
		echo "created link from $dotdir/$1 to $2"
	fi
}

create bin ~/bin
create vimrc ~/.vimrc
create vimdata ~/.vim
create zshrc ~/.zshrc
create zsh-z.plugin.zsh ~/.zsh-z.plugin.zsh
create xinitrc ~/.xinitrc
create gitconfig ~/.gitconfig
create reportbugrc ~/.reportbugrc
create dircolors ~/.dircolors
create screenrc ~/.screenrc
create Xdefaults ~/.Xdefaults
mkdir ~/.config
create awesome ~/.config/awesome
create tmux.conf ~/.tmux.conf
create irssi ~/.irssi
mkdir ~/.gnupg
create gpg-agent.conf ~/.gnupg/gpg-agent.conf
mkdir -p ~/.config/inkscape/palettes/
create inkscape-cp-flatuicolors.gpl ~/.config/inkscape/palettes/inkscape-cp-flatuicolors.gpl
mkdir -p ~/.config/nvim/
create init.lua ~/.config/nvim/init.lua
mkdir -p ~/.config/alacritty
create alacritty.yml ~/.config/alacritty/alacritty.yml
mkdir -p ~/.config/kitty
create kitty.conf ~/.config/kitty/kitty.conf
create ranger ~/.config/ranger

# Wayland: Hyprland + niri (Tokyo Night), shared bar/launcher/notifications/logout
if [ "$(cat /etc/hostname 2>/dev/null)" = "devnull" ]; then
	create hosts/devnull/hypr ~/.config/hypr
	create hosts/devnull/waybar ~/.config/waybar
	create hosts/devnull/quickshell ~/.config/quickshell
	create hosts/devnull/kitty/local.conf ~/.config/kitty/local.conf
	mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
	create hosts/devnull/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini
	create hosts/devnull/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini
	create hosts/devnull/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css
	create hosts/devnull/mimeapps.list ~/.config/mimeapps.list
else
	create hypr ~/.config/hypr
	create waybar ~/.config/waybar
fi
create niri ~/.config/niri
create fuzzel ~/.config/fuzzel
create mako ~/.config/mako
create wlogout ~/.config/wlogout
create imv ~/.config/imv
mkdir -p ~/.local/share/wm
create wm/bin ~/.local/share/wm/bin
create wm/wlogout ~/.local/share/wm/wlogout
create wm/wallpapers/synthwave_4k_purple.jpg ~/.local/share/wm/wallpaper


# blacklist things, no differentiation here
sudo cp module-blacklist.conf /etc/modprobe.d/
sudo cp iwlwifi.conf /etc/modprobe.d/
