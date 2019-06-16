#!/usr/bin/env zsh

zparseopts -D -E -- -select:=arg_selection -interactive::=arg_interactive

# '--interactive' presents a dmenu and reruns this script with the choice.
if [[ ! -z $arg_interactive ]]; then
  choice=$(echo "Area\nWindow\nScreen" | dmenu -p "Capture ")
  [[ -z $choice ]] && echo "Abort. Nothing done." && exit 0
  $0 --select=$choice
  exit 0
fi

# '--select=Area|Window|Screen' makes a snapshot, saves it to disk and puts it into the clipboard
outfile=$(mktemp --tmpdir=/tmp --suffix=.png snapshot_XXXXX)
if [[ ! -z $arg_selection ]]; then
  # remove the leading '=' from the choice (zparseopts why??)
  choice=$(echo "$arg_selection[2]" | tr -d '=')
  case $choice in
    Area)
      gnome-screenshot --file=$outfile -a
      notify-send "Saved to $outfile."
      ;;
    Window)
      notify-send "Window capture not yet implemented."
      ;;
    Screen)
      notify-send "Window capture not yet implemented."
      ;;
    *)
      echo "'$choice'? What is this? I don't even."
      rm $outfile
      exit 1
      ;;
  esac
fi
