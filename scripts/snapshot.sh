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
      xclip -t image/png -selection clipboard "$tmpdir/snapshot.png"
    action=$(dunstify \
      -I "$outfile" \
      --timeout=5000 \
      --action="default,Save to:" \
      "Snapshot")
    if [ "$action" = "default" ]; then
      # TODO(feat): show lf save-file dialog
      spacefm "$tmpdir" &
    fi
    ;;
esac
