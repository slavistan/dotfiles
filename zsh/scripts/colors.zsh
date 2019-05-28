#!/bin/bash

# Script to show the colours used for different file types

# This is just a more readable version of the 'eval' code at:
#     http://askubuntu.com/a/17300/309899

# A nice description of the colour codes is here:
#     http://askubuntu.com/a/466203/309899

case $1 in
  dircolors)
    IFS=:
    for SET in $LS_COLORS
    do
        TYPE=$(echo $SET | cut -d"=" -f1)
        COLOUR=$(echo $SET | cut -d"=" -f2)
        case $TYPE in
            no) TEXT="Global default";;
            fi) TEXT="Normal file";;
            di) TEXT="Directory";;
            ln) TEXT="Symbolic link";;
            pi) TEXT="Named pipe";;
            so) TEXT="Socket";;
            do) TEXT="Door";;
            bd) TEXT="Block device";;
            cd) TEXT="Character device";;
            or) TEXT="Orphaned symbolic link";;
            mi) TEXT="Missing file";;
            su) TEXT="Set UID";;
            sg) TEXT="Set GID";;
            tw) TEXT="Sticky other writable";;
            ow) TEXT="Other writable";;
            st) TEXT="Sticky";;
            ex) TEXT="Executable";;
            rs) TEXT="Reset to \"normal\" color";;
            mh) TEXT="Multi-Hardlink";;
            ca) TEXT="File with capability";;
            *) TEXT="${TYPE} (TODO: get description)";;
        esac
        printf "Type: %-10s Colour: %-10s \e[${COLOUR}m${TEXT}\e[0m\n" "${TYPE}" "${COLOUR}"
    done
    ;;
  
  ansicolors)
    for ii in $(seq 0 255); do
      echo -e "\033[38;5;"$ii"mBANANARAMA\033[m"
    done
    ;;

  truecolors)
    awk 'BEGIN{
           s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
           for (colnum = 0; colnum<77; colnum++) {
             r = 255-(colnum*255/76);
             g = (colnum*510/76);
             b = (colnum*255/76);
             if (g>255) g = 510-g;
             printf "\033[48;2;%d;%d;%dm", r,g,b;
             printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
             printf "%s\033[0m", substr(s,colnum+1,1);
           }
           printf "\n";
         }'
    ;;
esac
