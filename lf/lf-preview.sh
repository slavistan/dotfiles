#!/usr/bin/env bash

#
# lf previewer script. Executing lf instance must be called by lfrun, which
# defines LF_TEMPDIR and LF_FIFO_UEBERZUG and initializes ueberzug previews.
# This script it not meant to be run on its own.
#

# Clear the last preview (if any)
declare -p -A cmd=([action]=remove [identifier]="preview") \
	> "$LF_FIFO_UEBERZUG"

filepath="$1"
case "$filepath" in
*.tar*) tar tf "$filepath" ;;
*.zip) unzip -l "$filepath" ;;
*.rar) unrar l "$filepath" ;;
*.7z) 7z l "$filepath" ;;
*.avi|*.mp4)
	thumbnail="$LF_TEMPDIR/thumbnail.png"
	ffmpeg -y -i "$filepath" -vframes 1 "$thumbnail"
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$thumbnail") > "$LF_FIFO_UEBERZUG"
	;;
*.pdf)
	thumbnail="$LF_TEMPDIR/thumbnail.png"
	gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$filepath" >/dev/null
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$thumbnail") > "$LF_FIFO_UEBERZUG"
	;;
*.jpg|*.jpeg|*.png|*.bmp)
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$filepath") > "$LF_FIFO_UEBERZUG"
	;;
*.svg)
	thumbnail="$LF_TEMPDIR/thumbnail.png"
	convert "$filepath" "$thumbnail"
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$thumbnail") > "$LF_FIFO_UEBERZUG"
	;;
*) bat --style plain --paging never --color always "$filepath" ;;
esac
return 127 # nonzero retcode required for lf previews to reload
