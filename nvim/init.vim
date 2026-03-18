let g:NVIMHOME=$XDG_CONFIG_HOME . '/nvim'


""" Jump to and erasae placeholder (-++-) and enter insert mode
nnoremap <Leader><Space> /-++-<CR>4x:noh<CR>i

nnoremap <Leader>yy ^yg_
nnoremap <Leader>dd ^dg_

function! s:real_path(path) abort
  let l:path = a:path

  " VS Code Remote SSH URI:
  " vscode-remote://ssh-remote%2Bhost/home/user/file
  if l:path =~# '^vscode-remote://'
    let l:path = substitute(l:path, '^vscode-remote://[^/]*/', '/', '')
  endif

  return l:path
endfunction

command! CopyRelativeFilepath let @+ = fnamemodify(<SID>real_path(expand('%')), ':.') | echo 'Copied: ' . @+
command! CopyAbsoluteFilepath let @+ = <SID>real_path(expand('%:p')) | echo 'Copied: ' . @+
command! CopyFilename         let @+ = expand('%:t') | echo 'Copied: ' . @+

nnoremap <Leader>crp :CopyRelativeFilepath<CR>
nnoremap <Leader>cap :CopyAbsoluteFilepath<CR>
nnoremap <Leader>cn :CopyFilename<CR>

augroup highlight_yank
	autocmd!
	au TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=100}
augroup END

""" Configuration for vscode's neovim plugin (github.com/vscode-neovim/vscode-neovim)
if exists('g:vscode')
  set clipboard=unnamedplus
  set ignorecase
  set smartcase
  set noincsearch " Fixes spurious crashes (sometimes?), see issues/2165#issuecomment-2337491521
  set virtualedit=block

  nnoremap <Leader>yy ^yg_
  nnoremap <Leader>dd ^dg_

	" VSCode spuriously opens closed folds when navigating over them.
	" This ostensibly 'fixes' the issue. See #58.

   nmap j gj
   nmap k gk

	" <Tab> switches between opened tabs. We need the ':Tab' instead of ':tab'
	" or things won't work. See #241.

	nnoremap <Tab> :Tabnext<CR>
	nnoremap <S-Tab> :Tabprev<CR>

  " Hide diagnostic squiggles in insert mode by making them transparent
  lua << EOF
  local vscode = require('vscode')

  local function set_diagnostics(visible)
    local js = [[
      const config = vscode.workspace.getConfiguration('workbench');
      const current = config.get('colorCustomizations') || {};
      const updated = { ...current };
      const keys = [
        'editorError.foreground',
        'editorWarning.foreground',
        'editorInfo.foreground',
        'editorHint.foreground',
        'editorError.background',
        'editorWarning.background',
        'editorInfo.background',
        'editorHint.background',
        'errorLens.errorForeground',
        'errorLens.errorBackground',
        'errorLens.errorForegroundLight',
        'errorLens.warningForeground',
        'errorLens.warningBackground',
        'errorLens.warningForegroundLight',
        'errorLens.infoForeground',
        'errorLens.infoBackground',
        'errorLens.infoForegroundLight',
        'errorLens.hintForeground',
        'errorLens.hintBackground',
        'errorLens.hintForegroundLight',
        'errorLens.statusBarErrorForeground',
        'errorLens.statusBarWarningForeground',
        'errorLens.statusBarInfoForeground',
        'errorLens.statusBarHintForeground',
      ];
      if (args) {
        for (const k of keys) delete updated[k];
      } else {
        for (const k of keys) updated[k] = '#00000000';
      }
      await config.update('colorCustomizations', updated, vscode.ConfigurationTarget.Global);
    ]]
    vscode.eval_async(js, { args = visible })
  end

  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function() set_diagnostics(false) end,
  })
  vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function() set_diagnostics(true) end,
  })
EOF

  execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
  Plug 'https://github.com/godlygeek/tabular.git'
  call plug#end()

else


"""
" Settings
"
" Some settings must precede the loading of plugins.
"""
set termguicolors

" Cursor shapes
let &t_SI .= "\<Esc>[5 q"
let &t_SR .= "\<Esc>[4 q"
let &t_EI .= "\<Esc>[3 q"

let g:sh_fold_enabled=5 " Must precede fold settings

set updatetime=100
set clipboard=unnamedplus " Copy to clipboard
set foldlevelstart=99 " Open all folds
set foldlevel=99 " Open all folds
set foldmethod=syntax
set noincsearch
set ignorecase
set smartcase
set linebreak
set virtualedit=block
set path+=**
set scrolloff=3
set mouse=a " comfy mouse mode: select, resize windows
set signcolumn=number " integrate signcolumn into linenumber col

set textwidth=0
set modeline
set showbreak=↪



" Line wrapping

set wrap
nnoremap \w :set wrap!<cr>

set number " show linenumbers
set cursorline " highlight current line

" Display tabs and trailing whitespaces
set list
set listchars=tab:→\ 
set listchars+=trail:·
set listchars+=extends:⋯
set listchars+=precedes:⋯
set tabstop=4 softtabstop=4 shiftwidth=4
" set expandtab
" set autoindent " Keep indentation level for wrapped lines
set breakindent " Wrapped lines preserve indentation


"""
" Key mappings
"""

" Use regular movement keys to navigate normally across wrapped lines
noremap <buffer> <silent> k gk
noremap <buffer> <silent> j gj
noremap <buffer> <silent> 0 g0
noremap <buffer> <silent> $ g$
onoremap <silent> j gj
onoremap <silent> k gk

" Buffer/Tab navigation

set hidden " Change buffers without saving
nnoremap <Tab> :tabnext<CR>
nnoremap <Backspace> :tabprev<CR>
nnoremap <S-Tab> :tabprev<CR>


"""
" Utility
"""
" Show highlight groups under cursor
function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

colorscheme milton " postpone loading of colorscheme so that plugins' hi groups will be known

endif
