" Configuration pertaining to the C++ language

autocmd FileType cpp call SetCppOptions()
function! SetCppOptions()

""" ALE configuration

" Many linters and LSP servers make use of a compilation database which is
" generated by CMake in the build directory. We symlink the file into the
" project's root directory to avoid any trouble with programs not being able
" to locate it. The next variable tells ALE to search for the database.
let g:ale_c_parse_compile_commands=1

" Now list the linters and tools we want to use and configure them afterwards.
if !exists('g:ale_linters')
  let g:ale_linters={}
endif
let g:ale_linters.cpp = [
      \ 'clangd',
      \ 'clangcheck',
      \ 'cppcheck', 
      \ 'clangtidy']

" clangcheck: 'compile_commands.json' is found by ALE. We just pass the
" documentation flag to clang in order to analyze the doxygen comments.
" TODO: WDocumentation does not seem to work. Check what's wrong here.
let g:ale_cpp_clangcheck_options='-extra-arg="Wdocumentation"'

" clangd's brains are based on an 'index' of the project. Provide the index by
" generating it manually using the clangd-indexer tool, or let clangd do it.
" We choose the latter method by passing it the '-background-index' flag.
let g:ale_cpp_clangd_options='-background-index'

" cppcheck: Enable all checks. We don't need to manually pass the path of the
" compile_commands.json as this is handled automatically by ALE.
let g:ale_cpp_cppcheck_options='--enable=all'

" clang-tidy: Nothing to do. clang-tidy automatically finds its project-
" specific dotfile if it's put inside the project's root directory.
let g:ale_cpp_clangtidy_options=''

""" Misc configuration
set textwidth=120
set formatoptions=r
set comments=srO:/**,mb:\ *,ex:\ */,://
endfunction
