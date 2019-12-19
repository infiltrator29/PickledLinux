#!/bin/sh
#
#  _____  _____ _______ _     _        _______ ______ 
# |_____]   |   |       |____/  |      |______ |     \
# |       __|__ |_____  |    \_ |_____ |______ |_____/
#                _    _ _  _ _  _ _  _ 
#                |    | |\ | |  |  \/  
#                |___ | | \| |__| _/\_                                                     
#
#
#    "Auto-configure usable Arch-based linux system"
#                    by Infiltrator
#
# totally based on Luke Smith's LARBS


### GET ARGUMENTS ###

while getopts ":a:r:b:p:h" o; do case "${o}" in
  h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -b: Dotfiles repo branch name (default: master)\\n  -p: Dependencies and programs csv (local file or url)\\n  -a: AUR helper (must have pacman-like syntax)\\n  -h: Show this message\\n" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	a) aurhelper=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

# -z option checks if string is zero
[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/infiltrator29/.dotfiles.git"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/infiltrator29/PickledLinux/master/progs.csv"
[ -z "$aurhelper" ] && aurhelper="yay"
[ -z "$repobranch" ] && repobranch="master"

name=$(whoami)

### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
grepseq="\"^[PGA]*,\""

error() { clear; printf "Oops... :( You have an EROOR:\\n%s\\n" "$1"; exit;}

welcomemsg() {\
  dialog --title "Welcome!" --msgbox "\
  Welcome to PickledLinux!\\n\\n\
  This script will help you install utility packages and configs for a fully functional Linux desktop.\\n\\n\

  It's a really fast and enjoyable ride!\\n\\n\

  NOTE: this script is based on LARBS <larbs.xyz>" 10 60
}

preinstallmsg() { \
	dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
	}

refreshkeys() { \
	dialog --infobox "Refreshing Arch Keyring..." 4 40
	pacman --noconfirm -Sy archlinux-keyring >/dev/null 2>&1
	}

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
	[ -f "/usr/bin/$1" ] || (
	dialog --infobox "Installing \"$1\", an AUR helper..." 4 50
	cd /tmp || exit
	rm -rf /tmp/"$1"*
	curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
	sudo -u "$name" tar -xvf "$1".tar.gz >/dev/null 2>&1 &&
	cd "$1" &&
	sudo -u "$name" makepkg --noconfirm -si >/dev/null 2>&1
	cd /tmp || return) ;}

gitmakeinstall() {
	dir=$(mktemp -d)
	dialog --title "PickledLinux Installation" --infobox "Installing \`$(basename "$1")\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 5 70
	git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
	cd "$dir" || exit
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return ;}

aurinstall() { \
	dialog --title "PickledLinux Installation" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 5 70
	echo "$aurinstalled" | grep "^$1$" >/dev/null 2>&1 && return
	sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
	}

pipinstall() { \
	dialog --title "PickledLinux Installation" --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 5 70
	command -v pip || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
	}

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' | eval grep "$grepseq" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"A") aurinstall "$program" "$comment" ;;
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}

putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
	dialog --infobox "Downloading and installing config files..." 4 60
	[ -z "$3" ] && branch="master" || branch="$repobranch"
	dir=$(mktemp -d)
	[ ! -d "$2" ] && mkdir -p "$2" && chown -R "$name:wheel" "$2"
	chown -R "$name:wheel" "$dir"
	sudo -u "$name" git clone -b "$branch" --depth 1 "$1" "$dir/gitrepo" >/dev/null 2>&1 &&
	sudo -u "$name" cp -rfT "$dir/gitrepo" "$2"
	}

finalize(){ \
	dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place." 12 80
	}

### SCRIPT ###

# Install dialog
installpkg dialog || error "Stop! You should be a root user. Check if you have an internet connection."

welcomemsg || error "User exited." 

preinstallmsg || error "User exited."

# Refresh Arch keyrings.
# refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."

dialog --title "PickledLinux Installation" --infobox "Installing \`basedevel\` and \`git\` for installing other software." 5 70
installpkg base-devel
installpkg git
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case


# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

# Make pacman and yay colorful and adds eye candy on the progress bar because why not.
grep "^Color" /etc/pacman.conf >/dev/null || sed -i "s/^#Color/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf


# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

manualinstall $aurhelper || error "Failed to install AUR helper."

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's home directory
putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"
rm -f "/home/$name/README.md" "/home/$name/LICENSE"


# This line, overwriting the `newperms` command above will allow the user to run
# serveral important commands, `shutdown`, `reboot`, updating, etc. without a password.
newperms "%wheel ALL=(ALL) ALL #PickledLinux
%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/yay,/usr/bin/pacman -Syyuw --noconfirm"

# Last message! Install complete!
finalize
clear
