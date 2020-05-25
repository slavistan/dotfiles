#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo \
"Wrapper around the tool \033[1mcolorpicker\033[0m. Usage:

  (1) $0 [ -c ]
      Pick color from crosshair, print to stdout and, optionally, copy #RRGGBB
      code to clipboard."
exit
fi

# Note: --preview does not seem to work with multiple monitors
color=$(colorpicker --short --one-shot)
echo "$color"

[ "$1" = "-c" ] && printf "$color" | xclip -selection clipboard
