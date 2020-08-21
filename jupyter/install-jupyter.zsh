__install_jupyter() {
  case "$1" in
    -h) cat <<-EOF
			Usage:
			  $0 -h  - Show this help
			  $0 -u  - Update existing installation
			
			  Install jupyter, jupyterlab, assorted kernels and plugins.
			EOF
      ;;
    -u)
      please pip3 install --upgrade jupyterlab
      please R -q -e 'install.packages("IRkernel")'
      R -q -e 'IRkernel::installspec(user=F, prefix="/usr/local/")'

      please pip3 install --upgrade zsh_jupyter_kernel
      please python3 -m zsh_jupyter_kernel.install --sys-prefix

      please pip3 install --upgrade bash_kernel
      please python3 -m bash_kernel.install

      please pip3 install --upgrade markdown-kernel
      please python3 -m  markdown_kernel.install

      please pip3 install --upgrade sos-notebook
      please python3 -m sos_notebook.install
      please jupyter labextension install transient-display-data
      please jupyter labextension install jupyterlab-sos

      please jupyter labextension install @axlair/jupyterlab_vim
      please jupyter labextension install @jupyterlab/toc

      please jupyter lab build
      ;;
    *)
      loglnprefix "jupyter" "Installing 'jupyter' ..."

      # jupyterlab (& ipython kernel)
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

      # markdown kernel
      please pip3 install markdown-kernel
      please python3 -m  markdown_kernel.install

      # jupyterlab extensions
      please jupyter labextension install @axlair/jupyterlab_vim
      please jupyter labextension install @jupyterlab/toc

      loglnprefix "jupyter" "... done installing 'jupyter'."
      ;;
  esac

  exit

}
