let g:NVIMHOME=$XDG_CONFIG_HOME . '/nvim'

""" Configuration for vscode's neovim plugin

if exists('g:vscode')
  set clipboard=unnamedplus
  set ignorecase
  set smartcase
  set virtualedit=block

  vnoremap <Tab> >gv
  vnoremap <S-Tab> <gv
  inoremap <S-Tab> <Backspace>

  nnoremap <Leader>yy ^yg_
  nnoremap <Leader>dd ^dg_

  " <Tab> switches between opened tabs. We need the ':Tab' instead of ':tab'
  " or things won't work. See #241.

  nnoremap <Tab> :Tabnext<CR>
  nnoremap <S-Tab> :Tabprev<CR>

  execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
  Plug 'https://github.com/godlygeek/tabular.git'
  call plug#end()

else

" TODO:
"      List number of matches when searching (custom command?)
"      Incsearch without the adhs jumps
"      C++: Automatically add comment header for line comments '// ... '
"      Use Ctrl + vimkeys to shift a line left, right, up and down


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

set clipboard=unnamedplus
set foldlevelstart=0 " Files are opened with all folds closed
set noincsearch
set ignorecase
set smartcase
set linebreak
set virtualedit=block
set path+=**
set scrolloff=999 " Center cursor vertically

set textwidth=999
set modeline
set showbreak=↪
let mapleader=","
let maplocalleader="\\"

" Netrw

let g:netrw_home=&backupdir
let g:netrw_liststyle=3
let g:netrw_banner=0
let g:netrw_browse_split=4
let g:netrw_winsize=25

" Disable line wrapping by default and set a hotkey to toggle it

set nowrap
nnoremap \w :set wrap!<cr>

" Enable line numbers by default and set a hotkey to toggle them

set nonumber " show linenumbers
set relativenumber "
" TODO(feat): Toggle between relative, absolute and no numbers

" Display tabs and trailing whitespaces
set list
set listchars=tab:⇤-⇥
set listchars+=trail:·
set listchars+=extends:⋯
set listchars+=precedes:⋯
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set autoindent " Keep indentation level for wrapped lines
set breakindent " Wrapped lines preserve indentation

"""
" Plugins
"""

" vim-pandoc et al.
let g:pandoc#spell#enabled = 0
let g:pandoc#syntax#conceal#use = 0
let g:pandoc#syntax#codeblocks#embeds#langs = ['python', 'R=r', 'bash=sh', 'lua']

" vimwiki
" TODO(feat): envvar WIKIHOME
exe 'source ' . g:NVIMHOME . '/config/vimwiki.vim'

" vim buffet
" TODO(impr): Write custom buffer/tab line. Leave the plugin madness behind.
let g:buffet_powerline_separators=1
let g:buffet_tab_icon="📖"
function! g:BuffetSetCustomColors()
  hi BuffetTab           guifg=#BBBBBB gui=bold      guibg=#045B88
  hi BuffetCurrentBuffer guifg=#FFFFFF guibg=#045B88
  hi BuffetBuffer  guibg=#262833 guifg=#949184
endfunction

execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
Plug 'vimwiki/vimwiki'
Plug 'https://github.com/vim-pandoc/vim-pandoc-syntax.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc.git'
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'https://github.com/godlygeek/tabular.git'
Plug 'https://github.com/w0rp/ale.git'
Plug 'bagrat/vim-buffet'
Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
Plug 'https://github.com/dbridges/vim-markdown-runner.git'
Plug 'https://github.com/alcesleo/vim-uppercase-sql'
Plug 'https://github.com/tpope/vim-commentary'
call plug#end()

let g:ale_lint_on_text_changed = 'never' " Lint only on save
let g:ale_lint_on_enter = 0 " Don't lint when entering a file
let g:ale_linters_explicit=1 " Don't use all linters by default

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

" Navigate across buffers using Tab

set hidden " Change buffers without saving
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" Control line indent using Tab

vnoremap <Tab> >gv
vnoremap <S-Tab> <gv
inoremap <S-Tab> <Backspace>

" Source configuration submodules

exe 'source ' . g:NVIMHOME . '/config/cpp.vim'
exe 'source ' . g:NVIMHOME . '/config/python.vim'
exe 'source ' . g:NVIMHOME . '/config/rust.vim'

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
exe 'source ' . g:NVIMHOME . '/scripts/vimtig/vimtig.vim'
set updatetime=100 " lessen reaction time
let g:gitgutter_enabled=1 " run by default
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

colorscheme milton " postpone loading of colorscheme so that plugins' hi groups will be known

endif
set conceallevel=0
