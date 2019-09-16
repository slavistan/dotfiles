#!/usr/bin/env sh

current_wid=$(xdotool getactivewindow)
ff_wid=$(xdotool search --name "Mozilla Firefox" | head -1)
xdotool windowactivate $ff_wid
xdotool key F5
xdotool windowactivate $current_wid
