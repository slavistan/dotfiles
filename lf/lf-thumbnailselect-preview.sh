#!/usr/bin/env bash

#
# lf previewer script when using thumbnail selection. Enables previews for
# image files without file extension (jpg is assumed).
#
# defines LF_TEMPDIR and LF_FIFO_UEBERZUG and initializes ueberzug previews.
# This script it not meant to be run on its own.
#

# Clear the last preview (if any)
declare -p -A cmd=([action]=remove [identifier]="preview") \
	> "$LF_FIFO_UEBERZUG"

imgpath="$1"
case "$imgpath" in
*)
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$imgpath") > "$LF_FIFO_UEBERZUG"
	;;
esac
return 127 # nonzero retcode required for lf previews to reload
