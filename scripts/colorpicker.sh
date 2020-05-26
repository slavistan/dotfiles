#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo \
"Wrapper around the tool \033[1mcolorpicker\033[0m. Usage:

  (1) $0
      Pick color from crosshair, print #RRGGBB to stdout and copy to
      clipboard."
exit
fi

# Note: --preview does not seem to work with multiple monitors
color=$(colorpicker --short --one-shot)
echo "$color"

printf "$color" | xclip -selection clipboard
