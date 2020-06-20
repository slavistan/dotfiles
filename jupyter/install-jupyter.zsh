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

    # vi-bindings for cells
    please pip3 install --upgrade jupyterlab
    please jupyter labextension install @axlair/jupyerlab_vim

    # Table of Contents
    please jupyter labextension install @jupyterlab/toc

    # sos
    please jupyter labextension install jupyerlab-sos

    # TODO(feat): Install jupyterlab kernels

    loglnprefix "jupyter" "... done installing 'jupyter'."
  else
    loglnprefix "jupyter" "Nothing to do."
  fi
}
