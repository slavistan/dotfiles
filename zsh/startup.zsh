## Load custom scripts
fpath=(~/.config/zsh/completions/ $fpath)
autoload -U compinit && compinit

## Spack
source /home/shuell/bin/program-files/spack/share/spack/setup-env.sh

## ls/tree when changing the directory
function chpwd() {
    emulate -L zsh
    #ls -a
    tree -L 1 -a --dirsfirst
}

## <CR> executes default command
# my-accept-line () {
#     ## check if the buffer does not contain any words
#     if [ ${#${(z)BUFFER}} -eq 0 ]; then
#         ## put newline so that the output does not start next to the prompt
#         echo
#         ## check if inside git repository
#         if git rev-parse --git-dir > /dev/null 2>&1 ; then
#             ##if so, execute `git status'
#             git status
#         else
#             ## else run `ls'
#             ls
#         fi
#     fi
#     ## in any case run the `accept-line' widget
#     zle accept-line
# }
# ## create a widget from `my-accept-line' with the same name
# zle -N my-accept-line
# ## rebind Enter, usually this is `^M'
# bindkey '^M' my-accept-line

## Unbind Ctrl-D
setopt IGNORE_EOF
