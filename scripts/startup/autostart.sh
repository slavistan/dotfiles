# This script is executed during startup of dwm

## Source environment variables

source ~/.profile

## Start sxhkd or, if running, reload config

if [ -z "$(pgrep sxhkd)" ]; then
  sxhkd &
else
  kill -SIGUSR1 "$(pgrep sxhkd)"
fi

## Start copyq daemon

if [ -z "$(pgrep copyq)" ]; then
  copyq &
fi

## Start compton (required for transparency)

if [ -z "$(pgrep compton)" ]; then
  compton &
fi

## Set background image

feh --bg-scale ~/dat/img/bgimg

# Load custom keyboard layout

setxkbmap -layout stan

# Execution machine-specific startup script

if [ -f "$DOTFILES/dwm/machine-specific.sh" ]; then
  $DOTFILES/dwm/machine-specific.sh
fi
