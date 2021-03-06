**Dotfiles Installation Script**

### Installation

```sh
git clone --recursive https://github.com/slavistan/dotfiles
```

Mind the *--recursive* flag.

### Usage

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
`./install.zsh --list-modules`. As `__install_funkymodule -h` is executed by the
master script ensure that the call returns promptly, for the parsing of modules
is performed in a sequential manner.

```sh
# Contents of ./funkymodule/install-funkymodule.zsh

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

When using the shell function's name `$0` in the usage help reply the master
script substitutes the `__install_`-prefix such that the proper usage command is
displayed when listing all available modules. For the example above the relevant
output of `./install.zsh --list-modules` is as follows:

```
funkymodule
  Usage:
    (1) ./install.zsh -m funkymodule
    (2) ./install.zsh -m funkymodule --help | -h

  Install the funky module (1) or print this help (2).
```

The properly installed module may be called via `./install.zsh -m funkymodule
arg0 arg1 ...`. Any arguments passed after the module name are directly
forwarded to the implementation. `./install.zsh -m funkymodule` is simply
a wrapper around the `__install_funkymodule` shell function. The responsibility
of correctly responding to calls and of proper handling of arguments lies fully
with the function implementation. Given the above `./install.zsh -m funkymodule
--help` will simply print the above usage help, albeit without the substituted
function name.

As a final remark note that the name of the subdirectory may be freely chosen as
well as the module's name provided the filename matches the pattern
`install-*sh` and the shell function name matches `__install_*`. Thus, creating
the above file as `./funky/install-funky.zsh` is equivalent to the solution
shown previously as the module's name is extracted by stripping the function name
from the `__install_` prefix.

#### Debugging

The master script `./installer.zsh` allows to call sourced functions directly.
`./installer.zsh -- my_function` will invoke `my_function` regardless of where
and when it was defined. When the function is called all of the script's context
is already available, i.e. all subdirectories have been traversed and all aptly
named `install-*sh` files have been sourced. As an example consider
`./install.zsh -- list_available_modules` which calls the function
`list_available_modules` defined in `./install.zsh`. It lists the names of all
available modules gathered from `__install_*` shell functions:

```
acpi
compton
dmenu
dwm
environment
light
misc
nvidia
nvim
prerequisites
st
sxhkd
xkb
zsh
```

This feature can be used for easy debugging of your custom modules. Another
additional preset function available from `./install.zsh` is
`list_installer_files` which prints all `install-*` files sourced by the master
script. In case of errors use it to check that your file has indeed been found.

#### Convenience Macros

`./install.zsh` defines a few useful macros and wrappers. As your module's code
is sourced by the master installer you can make use of the macros. You may
define you own function and variables inside your `install-mymodule` file and
use them ad libitum in your `__install_mymodule` function. Available macros
and variables include:

**please** Wrapper around the *sudo* command. Will prompt the user for the sudo
command only if necessary. Reuses a running sudo session. Usage:

```sh
please echo "Hello"
# > Enter your sudo password. OK.
# > Hello
please echo "World"
# > World
```

**mkcd** Like *cd* but silently creates the directory if it does not exist.

```sh
mkcd ~/bin/
# Install something here ...
```

**THISDIR** Variable which contains the full path to the directory in which
*install.zsh* resides. Useful as a basepoint to reference files stored
somewhere in the directory structure.

```sh
cp $THISDIR/mymodule/config.cfg ~/.config/mymodule
```

---

#### Roadmap & Todos

- zsh: Path in prompt shall expand as wide as can be displayed by the terminal
- zsh: Unscrew tab-expansion of paths.
