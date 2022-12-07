#!/bin/sh -ue

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi
if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi
if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi
if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# load xinitr modules
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

autorandr -c
dunst &
sxhkd &
( while :; do sleep 0.9; xsetroot -name "$(date '+%H:%M:%S')"; done ) &

# HACK: Why does this not work without the hack?
( sleep 3; DISPLAY=:1 xset r rate 150 50 )& # typematic delay and frequency
( sleep 3; DISPLAY=:1 setxkbmap k6 )&

# Disable screen blanking
xset s off
xset s noblank

st &
exec dwm
