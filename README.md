dotfiles
========

Usage
-----

	git clone git https://github.com/hgn/dotfiles.git $HOME/.dotfiles
	cd $HOME/.dotfiles
	./create-symlinks.sh

Warning
-------

The create-symlinks script will eventually create links you do not want! For
example: xinitrc will created which in turn enable awesome windowmanager.
Please check create-symlinks.sh and delete stuff you do not want!
