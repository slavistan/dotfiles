" Configuration pertaining to the python language

autocmd FileType python call SetPythonOptions()
function! SetPythonOptions()

""" ALE configuration

" Now list the linters and tools we want to use and configure them afterwards.
if !exists('g:ale_linters')
  let g:ale_linters={}
endif
let g:ale_linters.python = [
      \ 'flake8']

let g:ale_python_flake8_options="--max-line-length=120"

""" Misc configuration
set textwidth=100
set formatoptions=r
set comments=srO:/*,mb:\ *,ex:\ */,://
endfunction
