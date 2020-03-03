alias view='nvim -R'
alias vim=nvim
alias gst='git status'
mkcd () {
  if [ "$#" -eq 1 ]; then 
    mkdir -p "$@" && cd "$@"
  else
    echo "Requires exactly one argument. Nothing done" 1>&2
    return 1
  fi
}
gsap () {
  if [ "$(git rev-parse --is-inside-work-tree 2>&1)" = "true" ]; then
    git add -u
    git commit -am "stuff"
    git push
  else
    echo "This is not a git repository. Nothing done."
    return 1
  fi
}

