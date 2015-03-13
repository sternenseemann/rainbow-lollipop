# Installing rainbow lollipop

## Debian (Jessie)

	# apt-get install libgtk-3-dev libgee-0.8-dev libclutter-1.0-dev libzmq-dev libwebkit2gtk-4.0-dev libclutter-gtk-1.0-dev
	# apt-get install valac-0.26

	$ cmake . # or:
	$ cmake -DCMAKE_INSTALL_PREFIX=/usr/local . 

	$ make

	# make install # to install it


## ArchLinux
PKGBUILD will be submited to the AUR soon™.

	$ yaourt -S zeromq2 # or whatever tool you like
	$ cd archlinux/rainbow-lollipop-git
	$ makepkg -si
