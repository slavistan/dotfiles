#!/usr/bin/env zsh

main () {

####
# User interface for taking screenshots and video captures.
####

zparseopts -D -E -- -select:=arg_selection -interactive::=arg_interactive

# '--interactive' presents a dmenu and reruns this script with the choice.
if [[ ! -z $arg_interactive ]]; then
  choice=$(echo "Area\nWindow\nScreen" | dmenu -p "Capture ")
  [[ -z $choice ]] && echo "Abort. Nothing done." && exit 0
  $0 --select=$choice
  exit 0
fi

# '--select=Area|Window|Screen' makes a snapshot, saves it to disk and puts it into the clipboard
if [[ ! -z $arg_selection ]]; then
  outfile=$(mktemp --tmpdir=/tmp --suffix=.png snapshot_XXXXX) # create the output file
  choice=$(echo "$arg_selection[2]" | tr -d '=')               # remove leading '=' from choice
                                                               # Why doesn'y zparseopts remove it? :(
  case $choice in
    Area)
      gnome-screenshot --file=$outfile --area  # let user select an area to snapshot
                                               # TODO: snapshot_ <screen area>
      clipcopy_ $outfile                       # copy MIME file to clipboard
      notify_ "Saved to $outfile."             # send a notification
      ;;
    Window)
      notify_ "Window capture not yet implemented."
      ;;
    Screen)
      notify_ "Screen capture not yet implemented."
      ;;
    *)
      echo "'$choice'? What is this? I don't even."
      rm $outfile
      exit 1
      ;;
  esac
fi

} # main()

notify_() {
  notify-send $1
}

clipcopy_() {
  copyq copy image/png - < $1
}

main "$@"; exit
