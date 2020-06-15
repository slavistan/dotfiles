__install_libxft-bgra() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

  Installs libXft with BGRA-patch to handle colored emojis. See
  https://gitlab.freedesktop.org/xorg/lib/libxft/-/merge_requests/1
"
    exit 0
  elif [ -z "$(command -v libxft-bgra)" ] || [ "$1" = "--force" ]; then
    tmpdir=$(mktemp -d -t libXft-bgra-XXXXXX)
    cd "$tmpdir"
    wget "https://gitlab.freedesktop.org/xorg/lib/libxft/uploads/76c8a4233f7e0d2cd78ab863b93ff268/xft_2.3.2-3+zanc1.dsc"
    wget "https://gitlab.freedesktop.org/xorg/lib/libxft/uploads/bb83848c8fc1bad0f34c91b0b50586ca/xft_2.3.2.orig.tar.gz"
    wget "https://gitlab.freedesktop.org/xorg/lib/libxft/uploads/dedee41aacf23a2d39a2a00e744c313d/xft_2.3.2-3+zanc1.debian.tar.xz"
    dpkg-source -x "./xft_2.3.2-3+zanc1.dsc"
    cd "./xft-2.3.2"
    dpkg-buildpackage --no-sign
    cd ..
    please dpkg -i "libxft-dev_2.3.2-3+zanc1_amd64.deb"
    please dpkg -i "libxft2_2.3.2-3+zanc1_amd64.deb"
    rm -rf "$tmpdir"
    loglnprefix "libxft-bgra" "Done."
  else
    loglnprefix "libxft-bgra" "Nothing to do."
  fi
}
