#!/usr/bin/env sh

# Reloads firefox's current tab by emulating key presses. Used for reloading
# html pages on file change.
#
# firefox "/my/source/file.html"
# echo "/my/source/file.html" | entr -ps "/this/script.sh"
current_wid=$(xdotool getactivewindow)
ff_wid=$(xdotool search --name "Mozilla Firefox" | head -1)
xdotool windowactivate $ff_wid
xdotool key F5
xdotool windowactivate $current_wid
