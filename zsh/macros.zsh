# Aliases

alias view='nvim -R'
alias vim=nvim
alias gst='git status'


# Create directory and enter it

function mkcd () {
  [ "$#" -eq 1 ] && mkdir -p "$1" && cd "$1" || echo "Nothing done."
}


# Git - Stage All & Push

function gsap () {
  if [ "$(git rev-parse --is-inside-work-tree 2>&1)" = "true" ]; then
    git add -u
    git commit -am "stuff"
    git push
  else
    echo "This is not a git repository. Nothing done."
    return 1
  fi
}



