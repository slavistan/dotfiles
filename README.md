**Dotfiles Installation Script**

# Usage

Run `./install.zsh --help` for a basic overview or
`./install.zsh --list-modules` to list available modules and their usages.
Modules can be executed via `./install.zsh -m <module> <arg0> <arg1> ...`.

### Adding Custom Modules

Modules are added by implementing a specifically named shell function
`__install_mymodule` in a specifically named file `install-mymodule.zsh`. The
master script parses all aptly named files in subdirectories and makes their
funtionality available.

To make a custom module `funkymodule` available create the file
`./funkymodule/install-funkymodule.zsh` and put the implementation in a shell
function named `__install_funkymodule` (note the underscores). When prompted for
help via the *-h* or *--help* flag basic usage information shall be printed to
stdout. The usage information is displayed when listing available modules via
`./install.zsh --list-modules`.

```sh
__install_funkymodule() {
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

When using the shell function's name `$0` in the help reply the master script
substitutes the `__install_`-prefix such that the proper usage command is
displayed when invoking `./install.zsh --list-modules`. For the example above
the relevant output is as follows:

```sh
funkymodule
  Usage:
    (1) ./install.zsh -m funkymodule
    (2) ./install.zsh -m funkymodule --help | -h

  Install the funky module (1) or print this help (2).
```

The properly installed module may be called via
`./install.zsh -m funkymodule arg0 arg1 ...`. Any arguments passed after the
module name are directly forwarded to the implementation. `./install.zsh -m funkymodule`
is simply a wrapper around the `__install_funkymodule` shell function. The
responsibility of correctly responding to calls and of proper handling of arguments
lies fully with the implementation.

Note that the name of the subdirectory may be freely chosen as well as the
module's name provided the filename matches the pattern `install-*sh` and the
shell function name matches `__install_*`. Thus, creating the above file as
`./funky/install-funky.zsh` is equivalent to the solution shown below as the
module's name is extracted by stripping the function name from the `__install_`
prefix.

#### Convenience Macros

`./install.zsh` defines a few useful macros and wrappers. As your module's code
is sourced by the master installer you can make use of the macros. You may
define you own function and variables inside your `install-mymodule` file and
use them ad libitum in your `__install_mymodule` function.


