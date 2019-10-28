" Configuration pertaining to vimwikis

function! VimwikiPreLoad()
  " Remove mappings which use Tab
  let g:vimwiki_key_mappings = { 'links': 0, }
  let g:vimwiki_list = [{'path': '$HOME/wiki', 'path_html': '/tmp/wiki'}]
endfunction

autocmd FileType vimwiki call SetVimwikiOptions()
function! SetVimwikiOptions()

  " Remap what was mapped to tab and restore all the other keymappings which we
  " deleted above to their defaults.

  nmap q <Plug>VimwikiNextLink
  nmap Q <Plug>VimwikiPrevLink
  nmap <Leader>w<Leader>i <Plug>VimwikiDiaryGenerateLinks
  nmap <CR> <Plug>VimwikiFollowLink
  nmap <Backspace> <Plug>VimwikiGoBackLink
  nmap <Leader>wd <Plug>VimwikiDeleteLink
  nmap <Leader>wr <Plug>VimwikiRenameLink
  nmap <Leader>dn <Plug>VimwikiDiaryNextDay
  nmap <Leader>dN <Plug>VimwikiDiaryPrevDay
  nmap + <Plug>VimwikiNormalizeLink
  vmap + <Plug>VimwikiNormalizeLinkVisual

  " Misc settings

  set wrap
  set nonumber

  " Color settings

  hi VimwikiLink guifg=#F4D03F guibg=None gui=bold,underline

endfunction
