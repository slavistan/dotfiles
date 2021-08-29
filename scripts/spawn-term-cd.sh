#!/usr/bin/env sh

focused=$(xdotool getwindowfocus)
win_pid=$(xprop -notype -id $focused _NET_WM_PID | cut -d= -f2 | tr -d ' ')

echo $win_pid
if echo $win_pid | grep -q '^[0-9]+$'; then
	zsh-xi st <<EOF &
cd "/proc/$win_pid/cwd"
EOF
else
	st &
fi
