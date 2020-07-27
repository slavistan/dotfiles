""" Configuration pertaining to vimwikis

" Allow temporary wikis but don't hijack every .md file

let g:vimwiki_global_ext = 1
let g:vimwiki_ext2syntax = {'.wiki': 'markdown'}

" Todo-List marks

let g:vimwiki_listsyms = ' ○◐●✓'

"

let g:vimwiki_folding = 'list'

"

let g:vimwiki_key_mappings = { 'links': 0, }


autocmd FileType vimwiki call SetVimwikiOptions()
function! SetVimwikiOptions()

  " Remap what was mapped to tab and restore all the other keymappings which we
  " deleted above to their defaults.

  nmap <C-j> <Plug>VimwikiNextLink
  nmap <C-k> <Plug>VimwikiPrevLink
  nmap <CR> <Plug>VimwikiFollowLink
  nmap <C-Backspace> <Plug>VimwikiGoBackLink
  nmap <F12> <Plug>VimwikiRenameFile
  nmap <Space>l <Plug>VimwikiIncrementListItem
  nmap <Space>h <Plug>VimwikiDecrementListItem
  nmap <Space><Space> <Plug>VimwikiToggleListItem

  " Misc settings

  set fillchars=fold:·
  set nowrap
  set textwidth=120

  " Color settings

  hi VimwikiLink     guifg=#F4D03F guibg=None gui=bold,underline
  hi VimwikiWebLink1 guifg=#66D9EF guibg=None gui=bold
  hi Folded          guifg=#FD971F guibg=None gui=italic

  """
  """ Concealment logic
  """

  set conceallevel=3
  set concealcursor=nv
  au InsertEnter *.wiki :call Foo()
  fun! Foo()
    set conceallevel=0
    au BufWritePost *.wiki ++once :set conceallevel=3
  endfun

endfunction

let s:templates = {'link': '[🔗]()'}
fun! vimwiki#Template(what)
  let text = s:templates[a:what]
  let line = getline('.')
  call setline('.', strpart(line, 0, col('.') - 1) . text . strpart(line, col('.') - 1))
endfun

nmap ,wl :call vimwiki#Template('link')<CR>
