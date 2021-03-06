#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	printf "\
Usage:
	(1) $0 --select-area | -s

Takes a snapshot of your desktop.
"
	exit
fi

case "$1" in
	-s|--select-area)
		tmpdir=$(mktemp -p /tmp/ -d snapshot_XXXXXX)
		outfile="$tmpdir/snapshot.png"
		import "$outfile" &&
			# FIXME: pngs are pale inside anki when using xclip
			# xclip -t image/png -selection clipboard "$tmpdir/snapshot.png"
			copyq copy image/png - < "$tmpdir/snapshot.png"
		if saveto="$(lf-saveas -p "Save as:" -t f -s ~ -x)"; then
			cp "$outfile" "$saveto"
			dunstify -I "$saveto" -t 5000
		fi
		;;
esac

# snapchad:
#  - cache previous save-to directory
