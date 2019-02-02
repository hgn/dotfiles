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
create inkscape-cp-flatuicolors.gpl ~/.config/inkscape/palettes/inkscape-cp-flatuicolors.gpl.gpl

