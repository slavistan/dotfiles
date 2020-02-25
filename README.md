**Dotfiles Installation Script**

# Usage

Run `./install.zsh --help` for a basic overview.

### Adding Custom Modules

To make a custom module `funkymodule` available create the file
`./funkymodule/install-funkymodule.zsh` and put the implementation in a shell
function named `install_funkymodule`. When prompted for help via the *-h* or
*--help* flag basic usage information shall be printed to stdout. The usage
information is displayed when listing available modules via
`./install.zsh --list-modules`.

```sh
install_funkymodule() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  (1) $0
  (2) $0 --help | -h

Install the funky module (1) or print this help (2)."
    exit 0

  # ...
  # Your script here ...
  # ...
}
```
