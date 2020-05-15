#!/usr/bin/env sh

map=$(ls /usr/share/X11/xkb/symbols | dmenu -p 'Which layout?') && setxkbmap "$map"
$DOTFILES/scripts/dwm-status.sh -- kickrunning > /dev/null
