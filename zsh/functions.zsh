# Opens vim and echos the input to the terminal. Used to generate text to pipe to other commands FROM a text editor (just like what happens when using 'git commit').
vimcat() {
  trap 'rm $buffer'  1 2 3 6 # Make sure temporary gets deleted no matter how the script terminates
  buffer=$(mktemp) # Create a temporary
  $EDITOR $buffer > /dev/tty
  cat $buffer
}


