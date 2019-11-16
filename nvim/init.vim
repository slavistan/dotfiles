" TODO:
"      List number of matches when searching (custom command?)
"      Incsearch without the adhs jumps
"      C++: Automatically add comment header for line comments '// ... '
"      Use Ctrl + vimkeys to shift a line left, right, up and down
let g:NVIMHOME=$XDG_CONFIG_HOME . '/nvim'

"""
" Settings
"
" Some settings must preceed the loading of plugins.
"""
set termguicolors

" Cursor shapes
let &t_SI .= "\<Esc>[5 q"
let &t_SR .= "\<Esc>[4 q"
let &t_EI .= "\<Esc>[3 q"

let &backupdir=g:NVIMHOME . '/backup'
let &directory=&backupdir
let &shadafile=&backupdir . '/shada'
let g:netrw_home=&backupdir

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

" Disable line wrapping by default and set a hotkey to toggle it

set nowrap
nnoremap \w :set wrap!<cr>

" Enable line numbers by default and set a hotkey to toggle them

set number " show linenumbers
nnoremap \n :set number!<cr>

" Display tabs and trailing whitespaces
set list
set listchars=tab:⇤-⇥
set listchars+=trail:·
set listchars+=extends:⋯
set listchars+=precedes:⋯
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set autoindent " Keep indentation level for wrapped lines
set breakindent " Wrapped lines preserve indentation

exe 'source ' . g:NVIMHOME . '/config/vimwiki.vim'

"""
" Plugins
"""
execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'https://github.com/mboughaba/i3config.vim.git'
Plug 'https://github.com/jalvesaq/Nvim-R.git'
Plug 'https://github.com/godlygeek/tabular.git'
Plug 'https://github.com/w0rp/ale.git'
Plug 'https://github.com/vim-airline/vim-airline.git'
Plug 'https://github.com/vifm/vifm.vim'
Plug 'https://github.com/junegunn/fzf.vim'
Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }

" rmarkdown syntax. Requires pandoc-syntax and pandoc plugins

Plug 'vim-pandoc/vim-rmarkdown'
Plug 'https://github.com/vim-pandoc/vim-pandoc-syntax.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc.git'

" vimwiki - Adjust mapping which are mapped to tab by default

call VimwikiPreLoad()
Plug 'https://github.com/vimwiki/vimwiki.git'

call plug#end()

let g:ale_lint_on_text_changed = 'never' " Lint only on save
let g:ale_lint_on_enter = 0 " Don't lint when entering a file
let g:ale_linters_explicit=1 " Don't use all linters by default

" Enable powerline symbols for airline and vim-buffet

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1

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

" Make super star highlight but not jump around
nnoremap * :keepjumps normal! *``<cr>

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

"""
" Vifm - plugin
"""
" TODO: Open multiple selected files at once (handy when working a project)
" TODO: Open left tab in vim's working directory and the right tab in
"       the directory of the currently viewed file (or the home dir?)
let g:vifm_replace_netrw=1 " replace netrw with vifm
colorscheme milton " postpone loading of colorscheme so that plugins' hi groups will be known
