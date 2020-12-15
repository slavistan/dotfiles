#!/usr/bin/env sh

imgpath="$1"
dwmswallow $WINDOWID
case "$imgpath" in
*.pdf) zathura "$imgpath" ;;
*.jpg|*.jpeg|*.png|*.bmp) sxiv "$imgpath" ;;
esac
