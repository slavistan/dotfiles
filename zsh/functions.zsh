# Opens vim and echos the input to the terminal. Used to generate text to pipe to other commands FROM a text editor (just like what happens when using 'git commit').
vimcat() {
  trap 'rm $buffer'  1 2 3 6 # Make sure temporary gets deleted no matter how the script terminates
  buffer=$(mktemp) # Create a temporary
  $EDITOR $buffer > /dev/tty
  cat $buffer
}

function print256ColorRange() {
  for ii in $(seq $1 $2); do
    echo -e "\033[38;5;"$ii"mBANANARAMA\033[m"
  done
}

function printTrueColors() {
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
                                                                      }
