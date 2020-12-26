#!/usr/bin/env sh

filepath="$1"

case "$filepath" in
*.pdf)
	dwmswallow $WINDOWID
	zathura "$filepath"
	;;
*.jpg|*.jpeg|*.png|*.bmp)
	dwmswallow $WINDOWID
	sxiv "$filepath"
	;;
*.mp4|*.avi)
	dwmswallow $WINDOWID
	mpv "$filepath"
	;;
esac
