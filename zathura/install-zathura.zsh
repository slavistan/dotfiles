__install_zathura() {

  case "$1" in
  -h|--help)
    cat <<-EOF
		Usage: TODO
		EOF
    ;;
  i|install)
    tmp="$(mktemp -d -t zathura_XXXXXX)"
    cd "$tmp"
    git clone "https://github.com/pwmt/zathura" .
    meson build
    cd build
    ninja
    please ninja install
    ;;
  esac

}
