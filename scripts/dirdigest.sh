#!/usr/bin/env sh
# Gives overview of contents of cwd

# Config
MAXCHARS=16 # num of chars displayed per file
MAXROWS=4 # max num of rows displaying files or dirs
DIRP="🗃 " # directory prefix
FILEP="🗒 "  # file prefix
LINKP="📎"
MORECHARS=… # char inidicating that a file's name is longer than displayed

# Dependents; don't change
ncol=$(expr $(tput cols) / 21) # cols of items
nitems=$(expr $MAXROWS "*" $ncol)

  #cat; exit
ls -qoA1 -F -H --quoting-style=escape |
  tail -n +2 |
  sed 's/\\ /⎵/g' |
  tr -s ' ' |
  cut -d ' ' -f 1,8- |
  cut -b 1,11- |
  sed -E 's/l ([^ ]+) -> .*\/$/d \1\/ ->/g' |
  sed -E 's/l ([^ ]+) -> .*$/- \1\/ ->/g' |
  sort

#CONTINUEHERE
#TODO(fix): Sort is fucked. 'echo "d asdf\n- asdf\nd fdsa\n- fdsa" | sort'?

exit
  sed 's/^d/'"$DIRP"'/g' |
  sed 's/^-/'"$FILEP"'/g' |
  sed 's/^l/'"$LINKP"'/g'

exit

if [ "$1" = "DEBUG" ]; then
  find '.' -mindepth 1 -maxdepth 1 -type f |
    head -10 |
    sort |
    sed 's/^\.\///g' | # remove leading ./
    sed 's/ /⎵/g' |
    cat
  exit
fi


find '.' -mindepth 1 -maxdepth 1 -type d |
  head -n $(expr 1 + $nitems) |
  awk 'NR=='$(expr $nitems + 1)' {$0="[more dirs ...]"} 1' |
  sed 's/^\.\///g' | # remove leading ./
  sed 's/ /⎵/g' | # indicate whitespaces; TODO(perf): use nulls
  sed 's/\(.\{'$MAXCHARS'\}\)\(.\+\)$/\1'$MORECHARS'/g' | # prune names
  xargs printf '%-'$(expr $MAXCHARS + 1)'s\n' | # pad
  sed 's/^/'"$DIRP"' /g' | # prepend symbols
  paste -d ' ' $(for ii in $(seq 1 $ncol); do printf -- "- "; done) |
  sed 's/⎵/ /g' | # remove whicespace indicators
  cat

echo ""

find '.' -mindepth 1 -maxdepth 1 -type f |
  head -n $(expr 1 + $nitems) |
  awk 'NR=='$(expr $nitems + 1)' {$0="[more files ...]"} 1' |
  sed 's/^\.\///g' | # remove leading ./
  sed 's/ /⎵/g' | # indicate whitespaces; TODO(perf): use nulls
  sed 's/\(.\{'$MAXCHARS'\}\)\(.\+\)$/\1'$MORECHARS'/g' | # prune names
  xargs printf '%-'$(expr $MAXCHARS + 1)'s\n' | # pad
  sed 's/^/'"$FILEP"'  /g' | # prepend symbols
  paste -d ' ' $(for ii in $(seq 1 $ncol); do printf -- "- "; done) |
  sed 's/⎵/ /g' | # remove whicespace indicators
  cat

echo "Cols = $ncol"

echo "$(for ii in $(seq 1 $ncol); do printf -- "- "; done)"
