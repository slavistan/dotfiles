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


## Start dropbox daemon

dropbox start &


## Start compton (required for transparency)

if [ -z "$(pgrep compton)" ]; then
  compton &
fi


## Run dwm status bar script

$DOTFILES/scripts/dwm-status.sh &


## Set background image

if [ -f ~/dat/img/wall ]; then
  feh --bg-scale ~/dat/img/wall
else
  feh --bg-scale $DOTFILES/files/img/ubuntu-teal.jpg
fi


## Load custom keyboard layout

setxkbmap -layout k6


## Run monitor setup

if [ -f "$DOTFILES/scripts/startup/monitor-setup.sh" ]; then
  $DOTFILES/scripts/startup/monitor-setup.sh
fi


## Run machine-specific startup script

if [ -f "$DOTFILES/scripts/startup/machine-specific.sh" ]; then
  $DOTFILES/scripts/startup/machine-specific.sh
fi


## Display log

libreoffice ~/Dropbox/log.ods &
