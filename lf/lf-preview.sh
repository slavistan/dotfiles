#!/usr/bin/env bash

#
# lf previewer script. Executing lf instance must be called by lfrun, which
# defines LF_TEMPDIR and LF_FIFO_UEBERZUG and initializes ueberzug previews.
# This script it not meant to be run on its own.
#

# Clear the last preview (if any)
declare -p -A cmd=([action]=remove [identifier]="preview") \
	> "$LF_FIFO_UEBERZUG"

imgpath="$1"
case "$imgpath" in
*.tar*) tar tf "$imgpath" ;;
*.zip) unzip -l "$imgpath" ;;
*.rar) unrar l "$imgpath" ;;
*.7z) 7z l "$imgpath" ;;
*.pdf) pdftotext "$imgpath" - ;;
*.jpg|*.jpeg|*.png|*.bmp)
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$imgpath") > "$LF_FIFO_UEBERZUG"
	;;
*.svg)
	aspng="$LF_TEMPDIR/svg2png.png"
	convert "$imgpath" "$aspng"
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$aspng") > "$LF_FIFO_UEBERZUG"
	;;
*) bat --style plain --paging never --color always "$imgpath" ;;
esac
return 127 # nonzero retcode required for lf previews to reload
