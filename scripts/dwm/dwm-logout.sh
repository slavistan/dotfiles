#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0

Quits dwm and exits session. Prompts user for confirmation first.
"
  exit 0
fi

ans=$(echo "Yes\nCancel" | dmenu -p "Exit session and quit dwm?")
[ "$ans$" = "Yes" ] && kill -SIGQUIT $(pgrep dwm)
