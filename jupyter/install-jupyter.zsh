__install_jupyter() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install jupyter; WIP.
"
    exit 0
  elif [ -z "$(command -v jupyter)" ] || [ "$1" = "--force" ]; then
    loglnprefix "jupyter" "Installing 'jupyter' ..."

    # jupyterlab (& ipython kernel)
    # TODO(fix): Install packages into system dir (NOT root's home)
    #   pip3 has some --sys-dir flag. What about R?
    please pip3 install jupyterlab

    # R kernel
    please R -q -e 'install.packages("IRkernel")'
    R -q -e 'IRkernel::installspec(user=F, prefix="/usr/local/")'

    # zsh kernel
    please pip3 install zsh_jupyter_kernel
    please python3 -m zsh_jupyter_kernel.install --sys-prefix

    # bash kernel
    please pip3 install bash_kernel
    please python3 -m bash_kernel.install

    # sos kernel
    please pip3 install sos-notebook
    please python3 -m sos_notebook.install
    please jupyter labextension install transient-display-data
    please jupyter labextension install jupyterlab-sos

    # jupyterlab extensions
    please jupyter labextension install @axlair/jupyterlab_vim
    please jupyter labextension install @jupyterlab/toc

    loglnprefix "jupyter" "... done installing 'jupyter'."
  else
    loglnprefix "jupyter" "Nothing to do."
  fi
}
