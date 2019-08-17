" Configuration pertaining to the python language

autocmd FileType python call SetPythonOptions()
function SetPythonOptions()

""" ALE configuration

" Many linters and LSP servers make use of a compilation database which is
" generated by CMake in the build directory. We symlink the file into the
" project's root directory to avoid any trouble with programs not being able
" to locate it. The next variable tells ALE to search for the database.
let g:ale_c_parse_compile_commands=1

" For now we only want to enable those linters we explicitly specified. Keep
" the madness to a minimum during this phase of experimentation.
let g:ale_linters_explicit=1

" Now list the linters and tools we want to use and configure them afterwards.
if !exists('g:ale_linters')
  let g:ale_linters={}
endif
let g:ale_linters.python = [
      \ 'flake8']

endfunction
