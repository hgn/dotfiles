set background=dark
set nocompatible
set ttyfast
set visualbell t_vb=
set showmatch
set matchtime=2
set laststatus=2
set timeout timeoutlen=3000 ttimeoutlen=100
set backspace=indent,eol,start
set tabstop=2
set shiftwidth=2
set ruler
set viminfo='20,<50,s10,h,%
set incsearch
set hlsearch
set nobackup
set foldcolumn=0
set modeline
set modelines=10
set wmh=0
set switchbuf=useopen
set titlestring=%<%F\ %M%=%l/%L\ -\ %p%% titlelen=70
" dont show startup message when opening new file
set shortmess+=I

syntax on

"let g:ctrlp_user_command = 'find %s -type f'
let g:ctrlp_cmd = 'CtrlP'
" gnore files in .gitignore" 
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
" Set no max file limit
"let g:ctrlp_max_files = 0
"let g:ctrlp_working_path_mode = 'ar'
let g:ctrlp_by_filename = 1
let g:ctrlp_match_window = 'bottom,order:ttb,min:1,max:30,results:30'
let g:ctrlp_use_caching = 1
let g:ctrlp_open_new_file = 'v'
let g:ctrlp_mruf_max = 250

let g:netrw_banner=0
let g:netrw_altw=1
let g:netrw_liststyle=3
let g:netrw_browse_split = 1
let g:netrw_winsize = 35

" search recursively for :find
set path+=**

"silent! set splitvertical
"set splitbelow
"set splitright


"autocmd BufRead *.go set tabstop=4 shiftwidth=4 smarttab noexpandtab softtabstop=4 autoindent cindent
autocmd FileType go setlocal noet ts=8 sw=8 sts=8 autoindent cindent

let mapleader = ","
map <Leader> <Plug>(easymotion-prefix)

let g:EasyMotion_startofline = 0 " keep cursor colum when JK motion
let g:EasyMotion_smartcase = 1

"" persistant undo
"set undodir=~/.cache/vim
"set undofile
"set undoreload=10000

set relativenumber
set number


autocmd BufRead,BufNewFile *.py set tabstop=4 softtabstop=4 shiftwidth=4 smarttab expandtab autoindent cindent

highlight ExtraWhitespace ctermbg=red guibg=red
autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/

autocmd BufRead,BufNewFile *.js,*.html,*.css set tabstop=2 softtabstop=2 shiftwidth=2 smarttab autoindent

set statusline=
set statusline+=\[%n]                               "buffernr
set statusline+=\ %<%F\                             "File+path
set statusline+=\ %=\ %y\                           "FileType
set statusline+=\ %{''.(&fenc!=''?&fenc:&enc).''}   "Encoding
set statusline+=\ %{(&bomb?\",BOM\":\"\")}\         "Encoding2
set statusline+=\ %{&ff}\                           "FileFormat (dos/unix..)
set statusline+=\ row:\ %l/%L\                      "Rownumber/total
set statusline+=\ \ %m%r%w\ %P\ \                   "Modified? Readonly? Top/bot.

" Bash like keys for the command line
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

" Format the statusline
"set statusline=\ %F%m%r%h\ %w\ \ CWD:\ %r%{CurDir()}%h\ \ \ Line:\ %l/%L:%c
" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

function! CurDir()
    let curdir = substitute(getcwd(), '/home/pfeifer', "~", "g")
    return curdir
endfunction

set history=700
set t_Co=256

filetype plugin on
set ofu=syntaxcomplete#Complete
set fileencodings=ucs-bom,utf-8,latin1

ab _if fprintf(stderr, "DEBUG [%s:%4d] - \n", __FILE__, __LINE__);<Esc>F\i

"set t_Co=256

"switch spellcheck languages (http://www.vim.org/tips/tip.php?tip_id=1224)
let g:myLang = 0
let g:myLangList = [ "nospell", "de_de", "en_us" ]
function! MySpellLang()
let g:myLang = g:myLang + 1
if g:myLang >= len(g:myLangList) | let g:myLang = 0 | endif
if g:myLang == 0 | set nospell | endif
if g:myLang == 1 | setlocal spell spelllang=de_de | endif
if g:myLang == 2 | setlocal spell spelllang=en_us | endif
echo "language:" g:myLangList[g:myLang]
endf
map <F7> :call MySpellLang()<CR>
imap <F7> <C-o>:call MySpellLang()<CR> 

" what a stupid feature - mouse support for the terminal!
" If I want X I use X, or Emacs, ...
set mouse=c 
set mousehide


" makes scrolling more smother (:he scroll-smooth)
map <C-U> <C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y>
map <C-D> <C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E>


set tabpagemax=25

let c_space_errors=1
let c_ansi_typedefs=1
let c_ansi_constants=1
let c_no_bracket_error=1
let c_no_curly_error=1
let c_comment_strings=1
let c_gnu=1

let python_highlight_all=1

set ignorecase
set smartcase

set tags+=~/.vim/systags
if version >= 700
  " spelling files:
  " http://ftp.vim.org/pub/vim/runtime/spell/
  " move de.latin1.spl and de.latin1.sug to RUNTIME/spell
  set spelllang=de
  set sps=best,10
  set omnifunc=ccomplete#Complete
map <S-h> gT
map <S-l> gt
else
" spell check for the folloging files
  let spell_auto_type = "tex,mail,text,human"
  let spell_markup_ft = ",tex,mail,text,human,,"
  let spell_guess_language_ft = ""
endif

" Minimal number of screen lines to keep above and below the cursor
set scrolloff=3

" highlight advanced perl vars inside strings
let perl_extended_vars=1


"set tabpagemax=20

" nable extended % matching
runtime macros/matchit.vim

" shell like menu
set wildmenu
set wildignore=*.class,*.o,*.bak,*.swp
set wildmode=full
set wildchar=<Tab>

" faster scolling
nnoremap <C-e> <C-e><C-e><C-e>
nnoremap <C-y> <C-y><C-y><C-y>

"set hidden

"report after N lines changed; default is two
set report=1

"maximum mumber of undos
set undolevels=1000
set indentkeys=0{,0},!^F,o,O,e,=then,=do,=else,=elif,=esac,=fi,=fin,=fil,=done
set autoindent
filetype plugin indent on

" TEXT FORMATING

if has("autocmd")

  filetype on
    augroup filetype
    filetype plugin indent on
    autocmd BufNewFile,BufRead *.txt set filetype=human
		"autocmd BufRead *.py set tabstop=4 shiftwidth=4 smarttab expandtab softtabstop=4 autoindent smartindent
  augroup END

  "vim jumps always to the last edited line, if possible
  "autocmd BufRead *,.* :normal '"
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  "in human-language files, automatically format everything at 78 chars:
  autocmd FileType mail,human
         \ set spelllang=de formatoptions+=t textwidth=78 nocindent dictionary=/usr/share/dict/words

	autocmd FileType ruby set tabstop=4 shiftwidth=4 expandtab


  " mail macros
  augroup mail
      au!
      autocmd BufRead *html source $HOME/.vim/mail.vim
  augroup END

	" 80 is to short, especially for tables and the like
  autocmd FileType tex set formatoptions+=t textwidth=170 nocindent

  autocmd FileType c,cpp set formatoptions+=ro dictionary=$HOME/.vim/c_dictionary
                       \ tw=78 tabstop=8 shiftwidth=8 noexpandtab cindent

  "for Perl programming, have things in braces indenting themselves:
  autocmd FileType perl set smartindent tabstop=4 shiftwidth=4


  "in makefiles, don't expand tabs to spaces, since actual tab characters are
  "needed, and have indentation at 8 chars to be sure that all indents are tabs
  "(despite the mappings later):
  autocmd FileType make     set noexpandtab shiftwidth=8
  autocmd FileType automake set noexpandtab shiftwidth=8

endif " has("autocmd")



" COLORIZATION 

"common bg fg color
"highlight Normal        ctermfg=black ctermbg=white
"modus (insert,visual ...)
highlight modeMsg	    cterm=bold ctermfg=white  ctermbg=red
"active statusLine
highlight statusLine   cterm=bold ctermfg=yellow ctermbg=blue
"inactive statusLine
highlight statusLineNC 	cterm=bold ctermfg=black  ctermbg=white
"visual mode
highlight visual		cterm=bold ctermfg=yellow ctermbg=red
"cursor colors
highlight cursor        cterm=bold 
"vertical line on split screen
highlight VertSplit     cterm=bold ctermfg=black ctermbg=black
"searchpattern
highlight Search        cterm=bold ctermfg=black ctermbg=yellow

highlight LineNr        cterm=bold ctermfg=gray ctermbg=black
highlight CursorLineNr  cterm=bold ctermfg=white ctermbg=black


" highlight spell errors
highlight SpellErrors ctermfg=Red cterm=underline term=reverse

if version >= 700
   hi PmenuSel ctermfg=red ctermbg=cyan
endif

" MAPPINGS

"search the current word under cursor in all files in working directory
map <F3> :Sexplore<CR>

"F11 -> F12 == resize window
map <F11>   <ESC>:resize -5 <CR>
map <F12>   <ESC>:resize +5 <CR>



"common c command
ab #d #define
ab #i #include <.h><Esc>hhi<C-R><CR>

autocmd Filetype gitcommit setlocal spell textwidth=72

set comments=sl:/*,mb:\ *,elx:\ */

"set pastetoggle=<F10>
nnoremap <F10> :se invpaste paste?<Enter>
imap <F10> <C-O><F10>
set pastetoggle=<F10>


set showbreak=↳

" always keep searched string in the middle of the screen
nnoremap n nzzzv
nnoremap N Nzzzv

" dont move on *
nnoremap * *<c-o>


map <silent> <F8> :Lexplore<CR>


