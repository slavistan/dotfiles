" Configuration pertaining to vimwikis

let g:vimwiki_key_mappings = { 'links': 0, }
let g:vimwiki_list = [{'path': '~/dat/wiki', 'syntax': 'markdown', 'path_html': '~/dat/wiki/html'}]
let g:vimwiki_global_ext = 0
let g:vimwiki_listsyms = ' ○◐●✓'
let g:vimwiki_folding = 'list'

autocmd FileType vimwiki call SetVimwikiOptions()
function! SetVimwikiOptions()

  " Remap what was mapped to tab and restore all the other keymappings which we
  " deleted above to their defaults.

  nmap <C-j> <Plug>VimwikiNextLink
  nmap <C-k> <Plug>VimwikiPrevLink
  nmap <CR> <Plug>VimwikiFollowLink
  nmap <Backspace> <Plug>VimwikiGoBackLink
  nmap <F12> <Plug>VimwikiRenameFile
  nmap <Space>l <Plug>VimwikiIncrementListItem
  nmap <Space>h <Plug>VimwikiDecrementListItem

  nnoremap <Leader>w<Leader>i <Plug>VimwikiDiaryGenerateLinks
  nnoremap <Leader>wd <Plug>VimwikiDeleteLink
  nnoremap <Leader>dn <Plug>VimwikiDiaryNextDay
  nnoremap <Leader>dN <Plug>VimwikiDiaryPrevDay

  " Misc settings

  set fillchars=fold:·
  set wrap

  " Color settings

  hi VimwikiLink guifg=#F4D03F guibg=None gui=bold,underline
  hi Folded      guifg=FD971F  guibg=None gui=italic

endfunction
