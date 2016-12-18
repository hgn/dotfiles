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
