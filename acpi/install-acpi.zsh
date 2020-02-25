# TODO: Configure systemd to ignore the corresponding events
__install_acpi() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Configures selected ACPI events."
    exit 0
  fi

  loglnprefix "acpi" "Installing acpi events and actions ..."
  please rm -rf /etc/acpi/events /etc/acpi/actions
  please cp -r $DOTFILES/acpi/events /etc/acpi
  please cp -r $DOTFILES/acpi/actions /etc/acpi
  loglnprefix "acpi" "... done."
}
