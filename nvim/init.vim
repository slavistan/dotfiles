""" Paths

let g:NVIMHOME=$XDG_CONFIG_HOME . '/nvim'

" Crash if a directory is opened by accident
for param in argv()
  if isdirectory(param)
    quit
  endif
endfor

""" Configuration for vscode's neovim plugin

if exists('g:vscode')
  set clipboard=unnamedplus
  set ignorecase
  set smartcase
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

  execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
  Plug 'https://github.com/godlygeek/tabular.git'
  call plug#end()

	augroup highlight_yank
		autocmd!
		au TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=100}
	augroup END

else

" TODO:
"      List number of matches when searching (custom command?)
"      Incsearch without the adhs jumps
"      C++: Automatically add comment header for line comments '// ... '

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
let mapleader=","
let maplocalleader="\\"



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
" Plugins
"""

" vim-pandoc et al.
let g:pandoc#spell#enabled = 0
let g:pandoc#syntax#conceal#use = 0
let g:pandoc#syntax#codeblocks#embeds#langs = ['python', 'R=r', 'bash=sh', 'lua', 'sqlhana']


execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
Plug 'https://github.com/vim-pandoc/vim-pandoc-syntax.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc.git'
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'https://github.com/godlygeek/tabular.git'
Plug 'https://github.com/lukelbd/vim-tabline.git'
Plug 'https://github.com/dbridges/vim-markdown-runner.git'
Plug 'https://github.com/tpope/vim-commentary'
call plug#end()

"""
" Key mappings
"""
nnoremap <Leader>yy ^yg_
nnoremap <Leader>dd ^dg_

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

"""
" Git + gitgutter
"""
let g:gitgutter_enabled=0 " disable by default
let g:gitgutter_highlight_lines=1 " highlight lines by default
" toggle on/off
nnoremap <Leader>gg :GitGutterToggle<CR>
" toggle folding of unchanged lines
nnoremap <Leader>gi :GitGutterFold<CR>
nnoremap <Leader>gn :GitGutterNextHunk<CR>
nnoremap <Leader>gN :GitGutterPrevHunk<CR>
nnoremap <Leader>gs :GitGutterStageHunk<CR>
nnoremap <Leader>gu :GitGutterUndoHunk<CR>
" reView a hunk in split screen
nnoremap <Leader>gv :GitGutterPreviewHunk<CR>
nnoremap <Leader>gc :call VimtigCommit()<CR>
nnoremap <Leader>ga :call VimtigStageFullBuffer()<CR>
nnoremap <Leader>gp :call VimtigPush()<CR>

let g:gitgutter_sign_added = '++'
let g:gitgutter_sign_modified = '≠≠'
let g:gitgutter_sign_removed = '--'
let g:gitgutter_sign_removed_first_line ='--'
let g:gitgutter_sign_modified_removed = '≠≠'

augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=100}
augroup END

colorscheme milton " postpone loading of colorscheme so that plugins' hi groups will be known

endif
