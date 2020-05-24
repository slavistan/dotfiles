#!/usr/bin/env sh

# Script to show the colours used for different file types

# This is just a more readable version of the 'eval' code at:
#     http://askubuntu.com/a/17300/309899

# A nice description of the colour codes is here:
#     http://askubuntu.com/a/466203/309899

case $1 in
  ansicolors)
    for ii in $(seq 0 255); do
      echo "\033[38;5;"$ii"mIs this the real life?\033[m"
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
