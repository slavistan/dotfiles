# This file is sourced by zsh login shells. zsh only loads ~/.zprofile but not
# ~/.profile due to incompatibilities with other shells. In order to retain the
# usage of ~/.profile for the sake of compatibility with other systems we
# source ~/.profile.

emulate sh
. ~/.profile
emulate zsh
