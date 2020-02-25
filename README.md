**Dotfiles Installation Script**

# Usage

Run `./install.zsh --help` for a basic overview or
`./install.zsh --list-modules` to list available modules and their usages.
Modules can be executed via `./install.zsh -m <module> <arg0> <arg1> ...`.

### Adding Custom Modules

Modules are added by implementing a specifically named shell function
`install_mymodule` in a specifically named file `install-mymodule.zsh`. The
master script parses all 

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
