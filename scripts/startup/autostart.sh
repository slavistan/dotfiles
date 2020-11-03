# This script is executed during startup of dwm

## Source environment variables

. ~/.profile


## Start notification daemon

if ! pgrep dunst >/dev/null; then
  dunst &
fi


## Start sxhkd or, if running, reload config

if ! pgrep sxhkd >/dev/null; then
  sxhkd &
else
  kill -USR1 "$(pgrep sxhkd)"
fi


## Start copyq daemon

if ! pgrep copyq >/dev/null; then
  copyq &
fi


## Start compton (required for transparency)

if ! pgrep compton >/dev/null; then
  compton &
fi


## Run dwm status bar

{ dwmbricks 2>&1 | while read line; do
  printf "$(date '+%H:%M:%S': $line\n)"
done; } >> ~/.dwmbricks.log &


## Set background image

wallpaper.sh -r


## Load custom keyboard layout

setxkbmap -layout k6
dwmbricks -t keymap


## Run machine-specific startup script

if [ -f "$DOTFILES/scripts/startup/machine-specific.sh" ]; then
  $DOTFILES/scripts/startup/machine-specific.sh
fi
