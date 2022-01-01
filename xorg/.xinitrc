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
setxkbmap k6
# dunst &
st &

# TODO: Use a user service
# Hotkey daemon with live reload
sxhkd &
#(echo "$XDG_CONFIG_HOME/sxhkd/sxhkdrc" | entr pkill -SIGUSR1 sxhkd) &

# Set typematic delay
xset r rate 150 50

exec dwm
