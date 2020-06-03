#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "-?" ]; then
  printf "\
Usage:
  $0 [OPTION] FILENAME

  Scan a file for URLs (use '-' as filename to read from stdin). By default
  URLs are written to stdout. Option '-d' opens a dmenu to choose a single URL.
  Options '-c' / '-o' open a dmenu to choose a single URL to be copied to
  the clipboard / to be opened in the \$BROWSER.
"
  exit 0
fi

if [ "$#" -eq 2 ]; then
  infile="$2"
  opt="$(echo $1 | tr -d '-')"
else
  infile="$1";
fi

case $(echo $opt) in
  o) prompt="Open URL in browser:" ;;
  c) prompt="Copy URL to clipboard:" ;;
  d) prompt="Write URL to stdout:" ;;
esac

re='(((http|https|ftp)://|www.)[a-zA-Z0-9.]*[:]?[a-zA-Z0-9./@&%?$#=_-]*)|((magnet:\\?xt=urn:btih:)[a-zA-Z0-9]*)'
choice=$(sed 's/.*│//g' "$infile" |  tr -d '\n' | grep -aEo "$re" | sort | uniq | dmenu -l 10 -p "$prompt") || exit

case $(echo $opt) in
  o) printf '%s\n' "$choice" | xargs $BROWSER ;;
  c) printf '%s\n' "$choice" | xclip -selection clipboard ;;
  d) printf '%s\n' "$choice" ;;
  *) cat ;;
esac
# TODO: Cancel when dmenu selection is aborted by user.
