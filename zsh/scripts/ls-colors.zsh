#!/bin/zsh
#
# This scripts converts the dircolors defined below into a `LS_COLORS`-compatible string. The definition syntax is deliberately kept close to the format required by `LS_COLORS`, which is a colon:separated list of key-color pairs. Details are explained below.
#
cat "$0"                            |
    awk '!/^ *#/ { print }'         | # throw away lines starting with #
    sed -re '1,/^exit 0$/ d'        | # remove these shell script lines
    sed -re 's/#.*$//g'             | # remove trailing comments
    sed -re 's/^ +//' -re 's/ +$//' | # remove leading and trailing whitespaces
    sed -re '/^$/d'                 | # remove blank lines
    sed -re '2,$ s/^/:/g'           | # prepend colon (excluding first line)
    tr -d '\n' # concatenate lines
exit 0

##
# Color definitions
#
# `LS_COLORS` accepts a colon-separated list of property:value pairs. See the list below for the different types of properties. The value consist of 
# {EFFECT};{COLOR};{BACKGROUND}
##
no=00;93 # Normal; Global default

di=01;32;40 # directory
ow=01;32;40 # directory (other-writable)
st=01;32;40 # directory (sticky)
tw=01;32;40 # directory (sticky + other-writable)
# 
ln=target # symlink
or=5;38;2;0;0;0;48;2;255;74;68 # orphan; symlink to non-existing target
mi=5;38;2;0;0;0;48;2;255;74;68 # missing; non-existing target of symlink
# 
fi=00;91;40 # file; normal file
ex=01;91;40 # executable;
# 
# pi=no # pipe
# do=no # door
# bd=no # block device
# cd=no # character device
# so=no # socket 
# su=no # setuid file
# sg=no # getuid file
# lc=no # leftcode; opening terminal code
# rc=no # rightcode; closing terminal code
# ec=5; # endcode; non-filename text (wut?)
# 
