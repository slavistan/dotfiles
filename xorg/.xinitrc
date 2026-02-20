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

# Java gui quick fix. See https://wiki.archlinux.org/title/java#Gray_window,_applications_not_resizing_with_WM,_menus_immediately_closing.
export _JAVA_OPTIONS='-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dawt.useSystemAAFontSettings=gasp' 
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit

autorandr -c
dunst &
sxhkd &

# machine-dependent dwm status bar
# statusbar="$HOME/.local/bin/statusbar"
# if [[ -x "$statusbar" ]]; then
# 	( while :; do sleep 0.9; xsetroot -name "$("$statusbar")"; done ) &
# fi

# machine-dependent background image
bgimg="$XDG_DATA_HOME/desktop-background"
if [[ -f "$bgimg" ]]; then
	feh --no-fehbg --bg-scale "$bgimg"
fi

# HACK: Why does this not work without the hack?
# ( sleep 3; DISPLAY=:0 xset r rate 150 50 )& # typematic delay and frequency
# ( sleep 3; DISPLAY=:0 setxkbmap k6 )&

# Disable screen blanking
# TODO: doesn't work
xset s off
xset s noblank

exec dwm
