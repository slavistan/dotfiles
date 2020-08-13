#!/usr/bin/env sh

map=$(ls /usr/share/X11/xkb/symbols | dmenu -p 'Which layout?') && setxkbmap "$map"
dwmbricks kick xkb
