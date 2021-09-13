#!/usr/bin/env sh

usage() {
	cat <<EOF
Usage:
	(1) $0 --select-area | -s

Takes a snapshot of your desktop.
"
EOF
}

make_tempdir() {
	mkdir -p "$SNAPCHAD_DIR"
}

SNAPCHAD_DIR="$XDG_RUNTIME_DIR/snapchad"

case "$1" in
--select-area)
	make_tempdir
	outfile="$SNAPCHAD_DIR/previous-snapshot.png"
	import "$outfile"
	xclip -t image/png -selection clipboard "$SNAPCHAD_DIR/previous-snapshot.png"
			# copyq copy image/png - < "$tmpdir/previous-snapshot.png"
			# FIXME: pngs are pale inside anki when using xclip
		# if saveto="$(lf-filedialog -p "Save as:" -t f -s ~ -x)"; then
		# 	cp "$outfile" "$saveto"
		# 	dunstify -I "$saveto" -t 5000
		# fi
		;;
	--help|-h) usage ;;
esac

# --repeat) repeat last action ;;
# --select-window) ;;
# --windowid) ;;

# snapchad:
#  - cache previous save-to directory
#  - 
#  - HOTKEY + Shift -> Additional options
