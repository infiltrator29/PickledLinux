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
# inspired by Luke Smith's LARBS


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
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/LukeSmithxyz/LARBS/master/progs.csv"
[ -z "$aurhelper" ] && aurhelper="yay"
[ -z "$repobranch" ] && repobranch="master"



### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
grepseq="\"^[PGA]*,\""

errorhandle() { clear; printf "Oops... :( You have an EROOR:\\n%s\\n" "$1"; exit;}

welcomemsg() {\
  dialog --title "Welcome!" --msgbox "\
  Welcome to PickledLinux!\\n\\n\
  This script will help you install utility packages and configs for a fully functional Linux desktop.\\n\\n\

  It's a really fast and enjoyable ride!\\n\\n\

  NOTE: this script is based on LARBS <larbs.xyz>" 10 60
}

installpkg dialog || errorhandle "Stop! You should be a root user. Check if you have an internet connection."

welcomemsg
