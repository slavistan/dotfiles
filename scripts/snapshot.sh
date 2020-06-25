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
    tmpdir=$(mktemp -d snapshot_XXXXXX)
    outfile="$tmpdir/snapshot.png"
    import "$outfile" || exit
    copyq copy image/png - < $outfile
    action=$(dunstify \
      -I "$outfile" \
      --timeout=3000 \
      --action="default,Save to:" \
      "Snapshot")
    if [ "$action" = "default" ]; then
      # TODO(feat): show lf save-file dialog
      spacefm "$tmpdir" &
    fi
    ;;
esac
