# Hagen Paul Pfeifer - hagen@jauu.net
# http://www.jauu.net

# core dumps up to 10000 blocks
ulimit -c 10000

# file creation mask
if (( EUID == 0 )); then
    umask 022
fi

## ENV's

# executable directories
export GOPATH=$HOME/src/code/go
export PATH=/usr/local/bin:$HOME/.cargo/bin:$HOME/bin:/sbin:/usr/sbin/:${PATH}:$GOPATH/bin
export DEBUGINFOD_URLS="https://debuginfod.debian.net"

#export PAGER="col -b | view -c 'set nomod' -"
#export MANPAGER="col -b | view -c 'hi StatusLine ctermbg=green| set ft=man nomod nolist' -"
#export MANPAGER="sh -c 'col -bx | batcat -l man -p'"

# default encrypted session via rsync
export RSYNC_RSH=ssh

# Language Stuff
# english messages && time, utf8 support
# setting LC_ALL overwrite all other values and have prefedenvce
unset LC_ALL
export LANG=en_US.UTF-8            # Default language set to English (US)
export LANGUAGE=en_US              # Preferred language for menus and manpages set to English
export LC_CTYPE=de_DE.UTF-8        # Character encoding and keyboard layout set to German
export LC_NUMERIC=C                # Numeric formatting: decimal point, no thousands separators
export LC_TIME=de_DE.UTF-8         # Date and time format set to German
export LC_MONETARY=de_DE.UTF-8     # Currency format set to German
export LC_COLLATE=C                # Sorting order: standardized (important for programming)
export LC_MESSAGES=en_US.UTF-8     # System messages set to English
export LC_PAPER=de_DE.UTF-8        # Paper format set to German (A4)
export LC_MEASUREMENT=de_DE.UTF-8  # Measurement units set to German (metric)


## ALIASES
alias vim='nvim'

alias mutt-offline='mutt -F ~/.mutt/muttrc-offline'

alias bat='batcat --color always -pp'
alias l='exa -bl -s newest --color always --time-style=long-iso'
alias less="less -r"

# some piping stuff
alias -g V='|vim -'
alias -g L='|less'
alias -g LL=' 2>&1|less'
alias -g H='|head'
alias -g T='|tail'
alias -g G='|grep'
# for ^x^h
alias run-help='man'
# don't print copyright messages at startup
alias gdb="gdb -silent"

# verbose remove 5iterations zero force
alias shred="shred -v -u -n2 -z -f"

# sort symbols numerically by their addresses
alias nm="nm -n"
# no spelling corrections on this commands
alias mv="nocorrect mv"
alias cp="nocorrect cp"
alias mkdir="nocorrect mkdir"
alias grep='nocorrect grep --color=auto'
alias dirs='dirs -v'

# ls - list directory contents
alias d="ls --color=auto -T 0"
alias ls='LC_COLLATE=C ls -h --group-directories-first --color=auto'
alias la="ls --color=auto -Al -T 0"
alias ll="ls --color -l -T 0"

alias m="make"
alias v="vim"

# ls-tips
#   ls -sS    list for Size
#   ls -sSr   list for Reverse size
#   ls -t     list for youngest modification
#   ls -tr    list for oldest modification

alias rm="rm -if"
alias ..="cd .."
alias ...="cd .. ; cd .."
alias l.="ls -d .[A-Za-z]* --color=auto"
# checksuming it
alias rsync='rsync -P --checksum'

alias kindent='indent -npro -kr -i4 -ts4 -sob -l80 -ss -ncs'

# change current permissions for home directory
alias homeopen="chmod -R go=rX $HOME"
alias homeclose="chmod -R go= $HOME"

alias currentopen="chmod -R go=rX ."
alias currentclose="chmod -R go= ."

alias diff='LC_ALL=C TZ=UTC0 diff'

# hexdump
alias hd='od -Ax -tx1z -v'

# generate passwords, -t show you how to pronounce the generated passwords
alias apg='apg -t'

# Xterm stuff
alias xterm-default='echo -e "\033]50;fixed\007"'
alias xterm-tiny='echo -en "\033]50;5x7\007"'
alias xterm-small='echo -en "\033]50;6x10\007"'
alias xterm-medium='echo -en "\033]50;7x13\007"'
alias xterm-large='echo -en "\033]50;9x15\007"'
alias xterm-huge='echo -en "\033]50;10x20\007"'

# use readline, completion and require rubygems by default for irb
# http://planetrubyonrails.org/show/feed/172
alias irb='irb --readline -r irb/completion -rubygems'
alias 3339date='date --rfc-3339=date'
alias freq="cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq"
alias pyclean='find . -type f -name "*.py[co]" -exec rm -f \{\} \;'

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias clip='xclip -selection clipboard'

alias fd=fdfind

# git branch checkout
alias gitb='git branch --sort=-committerdate | fzf --height=20% | xargs git checkout '

[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

## get keys working
# found at http://maxime.ritter.eu.org/stuff/zshrc
case $TERM in 
  linux)
  bindkey "^[[2~" yank
  bindkey "^[[3~" delete-char
  bindkey "^[[5~" up-line-or-history ## PageUp
  bindkey "^[[6~" down-line-or-history ## PageDown
  bindkey "^[[1~" beginning-of-line
  bindkey "^[[4~" end-of-line
  bindkey "^[e" expand-cmd-path ## C-e for expanding path of typed command
  bindkey "^[[A" up-line-or-search ## up arrow for back-history-search
  bindkey "^[[B" down-line-or-search ## down arrow for fwd-history-search
  bindkey " " magic-space ## do history expansion on space
;;
  *xterm*|rxvt|(dt|k|E)term)
  bindkey "^[[2~" yank
  bindkey "^[[3~" delete-char
  bindkey "^[[5~" up-line-or-history ## PageUp
  bindkey "^[[6~" down-line-or-history ## PageDown
  bindkey "^[[7~" beginning-of-line
  bindkey "^[[8~" end-of-line
  bindkey "^[e" expand-cmd-path ## C-e for expanding path of typed command
  bindkey "^[[A" up-line-or-search ## up arrow for back-history-search
  bindkey "^[[B" down-line-or-search ## down arrow for fwd-history-search
  bindkey " " magic-space ## do history expansion on space
;;
esac

zmodload -i zsh/complist

# display colored directory entries
# display current dircolors with dircolors -p
if [ -f ${HOME}/.dir_colors ]
then
    eval $(dircolors -b ${HOME}/.dir_colors)
elif [ -f /etc/DIR_COLORS ]
then
    eval $(dircolors -b /etc/DIR_COLORS)
fi

zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#)*=36=31"

zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' file-sort modification

# use z, with menu
source ~/.zsh-z.plugin.zsh
zstyle ':completion:*' menu select


#zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
#zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
#zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Load the completion system
autoload -U compinit
compinit
zstyle ':completion:*:*:kill:*:jobs' verbose yes

autoload -U sched


# From the zshwiki. Hide CVS files/directores from being completed.
zstyle ':completion:*:(all-|)files' ignored-patterns '(|*/)CVS'
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#CVS'

# frequently used users names
_users=(pfeifer)
zstyle ':completion:*' users $_users

# Functions autoloading
autoload zmv

zstyle ':completion:*' completer _extensions _complete _approximate

# cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# turns off spelling correction for commands
setopt nocorrect
# ORRECTALL option turns on spelling correction for all arguments
setopt nocorrectall

#report to me when people login/logout
watch=(notme)

# let you type comment's
setopt interactivecomments

# autocd allow you to type a directory, without a cd prefix
#setopt autocd

# now you can negates pattern [ ls -d ^*.c ] and the like ;-)
setopt extendedglob

setopt EXTENDEDGLOB     # file globbing is awesome
setopt AUTOMENU         # Tab-completion should cycle.
setopt AUTOLIST         # ... and list the possibilities.
setopt AUTO_PARAM_SLASH # Make directories pretty.
setopt ALWAYS_TO_END    # Push that cursor on completions.
setopt AUTOCD           # jump to the directory.
setopt NO_BEEP          # self explanatory
setopt AUTO_NAME_DIRS   # change directories  to variable names
setopt CHASE_LINKS      # if you pwd from a symlink, you get the actual path
setopt AUTO_CONTINUE    # automatically sent a CONT signal by disown
setopt LONG_LIST_JOBS   # List jobs in the long format by default

# history related options
# number of commands that are stored in the zsh history file
SAVEHIST=2000000
# number of commands that are loaded into memory from the history file
HISTSIZE=$SAVEHIST
# path/location of the history file
HISTFILE=~/.zhistory
# dont save clutter
HISTORY_IGNORE="(ls|ll|rm|fg|cd|pwd|exit|cd ..)"
# Whenever the user enters a line with history expansion, don’t execute the line directly
setopt HIST_VERIFY
# records the timestamp of each command in HISTFILE
setopt EXTENDED_HISTORY
# do not write duplicates to the history file at all
setopt HIST_IGNORE_ALL_DUPS
# Remove function definitions from the history list
setopt HIST_NO_FUNCTIONS
# Remove superfluous blanks from each command line being added to the history list
setopt HIST_REDUCE_BLANKS


# some testings (found on http://zsh.sunsite.dk/Intro/intro_6.html)
export DIRSTACKSIZE=10
setopt autopushd pushdminus pushdsilent pushdtohome
alias dh='dirs -v'

setopt long_list_jobs
alias jobs='jobs -l'

alias fd="fdfind"

# aptitude install autojump
if [ -f /usr/share/autojump/autojump.zsh ]; then
	. /usr/share/autojump/autojump.zsh
fi


# red id indicator, if last 
function set_prompt {
  if [[ $? -eq 0 ]]; then
    # Last command was successful
    PROMPT=$'%{\e[01;33m%}\%1~ %{\e[01;32m%}$%{\e[0m%} '
  else
    # Last command failed
    PROMPT=$'%{\e[01;33m%}\%1~ %{\e[01;31m%}$%{\e[0m%} '
  fi
}

if [[ ${SSH_TTY} ]] ; then
   PROMPT=$'%{\e[01;35m%}\%1 @%m %{\e[01;33m%}\%1~ %{\e[01;32m%}$%{\e[0m%} '
else
  precmd_functions+=(set_prompt)
fi

export WORDCHARS=''
export DIRSTACKSIZE=30         # max push/pop stack

# emacs keybinding's
bindkey -e

# insert all expansions for expand completer
zstyle ':completion:*:expand:*' tag-order all-expansions

# formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
#zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''


# of course
export EDITOR='/usr/bin/nvim'

# favorite pager (give more information)
export PAGER='/usr/bin/less -M'


#############################################################################
# COMMANDLINE COMPLETITION SECTION

# only directories for cd && pushcd; nice feature!
# or "compctl -g '*(-/)' cd pushd" without hidden dirs
compctl -g '*(-/)' + -g '.*(-/)' -v cd pushd

# only java files for javac
compctl -g '*.java' javac

# for ssh && scp connection's
compctl -k hosts ssh scp


#############################################################################
# KEY - BINDINGS

# interactive help? type CTRL-x; CTRL-h
bindkey "^X^H" run-help
# search for command backward
bindkey "^r" history-incremental-search-backward
# emulate some bash feelings
#bindkey "" backward-delete-word

#############################################################################
# FUNCTIONS

# ps wrapper function definitions found on
# http://billharlan.com/pub/papers/Debugging_GnuLinux.txt
function psc {
  ps --cols=1000 --sort='-%cpu,uid,pgid,ppid,pid' -e \
     -o user,pid,ppid,pgid,stime,stat,wchan,time,pcpu,pmem,vsz,rss,sz,args |
     sed 's/^/ /' | less
}

function psm {
  ps --cols=1000 --sort='-vsz,uid,pgid,ppid,pid' -e \
     -o user,pid,ppid,pgid,stime,stat,wchan,time,pcpu,pmem,vsz,rss,sz,args |
     sed 's/^/ /' | less
}

function ff () {
  fd "${*}"
}

function ffg () {
  if [[ $# != 3 ]]
  then
    echo "Usage: $0 directory filenamepattern filecontentpattern"
  else
    find $1 -iregex $2 -print0 | xargs -0 grep -in $3
  fi
}

function lolbanner {
  figlet -c  $@ | /usr/games/lolcat
}

# the following funtion found on http://status.deifl-web.de/dotfiles/zsh/zshfunctions

# mkdir && cd
function mcd() { mkdir "$@"; cd "$@" }

# mkdir /tmp/$rand && cd
function mcdt() {
  local TMP=$(head -n 1000 /usr/share/dict/words | \
              sort -R | \
              tr -d "\'" | \
              tr '[:upper:]' '[:lower:]' | \
              head -n 1)
  TMP=/tmp/$TMP
  mkdir $TMP
  cd $TMP
  echo "Created and changed directory to $TMP"
}

# cd && ls
function cl() { cd $1 && ls -l }

# head and tail replacement
function h() { bat --color=always $@ | head -n 30 }
function t() { bat --color=always $@ | tail -n 30 }
function c() { batcat --color always --theme Dracula $@ }

# Usage: show-archive <archive>
# Description: view archive without unpack
show-archive()
{
	if [[ -f $1 ]]
	then
		case $1 in
			*.tar.gz)      gunzip -c $1 | tar -tf - -- ;;
			*.tar)         tar -tf $1 ;;
			*.tgz)         tar -ztf $1 ;;
			*.zip)         unzip -l $1 ;;
			*.bz2)         bzless $1 ;;
 			*.tbz2)         tar -jtf $1 ;;
			*)             echo "'$1' Error. Please go away" ;;
		esac
	else
		echo "'$1' is not a valid archive"
	fi
}

# Exchange ' ' for '_' in filenames.
unspaceit()
{
    for _spaced in "${@:+"$@"}"; do
        if [ ! -f "${_spaced}" ]; then
            continue;
    fi
        _underscored=$(echo ${_spaced} | tr ' ' '_');
    if [ "${_underscored}" != "${_spaced}" ]; then
        mv "${_spaced}" "${_underscored}";
    fi
        done
}

function fileenc()
{
  if [[ $# != 2 ]]
  then
    echo "Usage: $0 input-file output-file"
    echo "Purpose: encrypt a file via openssl with blowfish in CBC mode"
  else
    openssl enc -e -a -salt -bf -in $1 -out $2
    shred -n 1 -z -f -u -v $1
  fi
}

function filedec()
{
  if [[ $# != 2 ]]
  then
    echo "Usage: $0 input-file output-file"
    echo "Purpose: decrypt a file via openssl with blowfish in CBC mode"
  else
    openssl enc -d -a -bf -in $1 -out $2
    shred -n 1 -z -f -u -v $1
  fi
}

function gif2png() 
{
  if [[ $# = 0 ]]
  then
    echo "Usage: $0 foo.gif"
    echo "Purpose: change a GIF file to a PNG file"
  else
    output=`basename $1 .gif`.png
    convert  $1 $output
    ls -l $1 $output
  fi
}


function radio()
{
  if [[ $# != 1 ]]
  then
    echo "Usage: $0 [egofm | dlf ]"
		return
  fi

	case $1 in
		egofm)
			mplayer "https://streams.egofm.de/egoRAP-hq"
			;;
		dlf)
			mplayer "https://st01.sslstream.dlf.de/dlf/01/high/opus/stream.opus?aggregator=web"
			;;
		*)
			echo "Usage: $0 [egofm | dlf ]"
			;;
	esac
}

ulimitall() {
  ulimit -c unlimited
  ulimit -d unlimited
  ulimit -f unlimited
  ulimit -l unlimited
  ulimit -n unlimited
  ulimit -s unlimited
  ulimit -t unlimited
}


# aptitude install apcalc
#alias calc="noglob _calc"
#function _calc () {
#             awk "BEGIN { print $* ; }"
#}

function mail-classify () {
  # linux-pm
	notmuch tag +linux-pm +list folder:Lists.linux-pm
	notmuch tag +keep-longer +linux-pm-intel -- tag:linux-pm and subject:\*intel\*
	notmuch tag +keep-longer +linux-pm-intel -- tag:linux-pm and subject:\*rapl\*
	notmuch tag +killed -- tag:linux-pm and not tag:keep-longer and date:..365days
	notmuch tag +killed -- tag:linux-pm and date:..1024days
  # lkml stuff
	notmuch tag +lkml +list folder:Lists.lkml
	notmuch tag +keep-infty -- tag:lkml and to:hagen.pfeifer@jauu.net
  # keep all messages which I tagged important for ever
	notmuch tag +keep-infty -- tag:flagged
	notmuch tag +keep-longer +linux-perf -- tag:lkml and subject:perf
	notmuch tag +keep-longer +linux-trace -- tag:lkml and subject:trace
	notmuch tag +keep-longer +linux-trace -- tag:lkml and subject:ftrace
	notmuch tag +keep-longer +linux-bpf  -- tag:lkml and subject:ebpf
	notmuch tag +keep-longer +linux-bpf  -- tag:lkml and subject:bpf
	# mark all messages older 1 month and not to me, not perf, trace as "killed"
  # please not, month means "not that month", not 30 days.
	notmuch tag +killed -- tag:lkml and not tag:keep-longer and not tag:keep-infty and date:..30days
	notmuch tag +killed -- tag:lkml and not tag:keep-infty and date:..365days
}
function mail-cleanup () {
  echo "did you call mail-classify first?"
	echo "now will delete killed tagged email"
	notmuch search tag:killed
	notmuch search --output=files --format=text0 tag:killed | xargs --null --no-run-if-empty rm
  notmuch new
}
function email-sync () {
	echo "Email Two-Way Synchronization Initiated"
	if ! ping -c 1 heise.de >/dev/null 2>&1; then
    echo "heise.de not pingable - failed to sync emails"
		return
  fi
	offlineimap -o -u basic
	mail-classify
	mail-cleanup
	offlineimap -o -u basic
	echo "tips:"
	echo "    notmuch search thread:{tag:linux-perf}"
	echo "    notmuch search --sort oldest-first thread:{tag:linux-perf} date:1month..now"
  echo "    notmuch search --format=json tag:flagged | jq -r '.[].subject'"
  echo "    notmuch show --format=json tag:flagged | jq -r"
  echo "    Available notmuch tags are"
  notmuch search --output=tags '*' | python3 -c 'import sys; print(", ".join(sys.stdin.read().splitlines()))'
	du -sh $HOME/.mail
}

eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

source /usr/share/doc/fzf/examples/key-bindings.zsh
#source /usr/share/zsh/vendor-completions/_fzf
export FZF_DEFAULT_OPTS='--height 100% --layout=reverse --border --exact'


alias mutt-offline-resync='email-sync 1>/dev/null 2>&1 &;mutt -F ~/.mutt/muttrc-offline; email-sync'
alias mutt-offline='mutt -F ~/.mutt/muttrc-offline'
alias mutt="neomutt"

alias mosh="mosh --no-init"

_feh_completion() {
    _files -g "*.png" -g "*.gif" -g "*.jpg"
}
compdef _feh_completion feh

_xpdf_completion() {
    _files -g "*.pdf"
}
compdef _xpdf_completion xpdf

autoload -Uz compinit
fpath+=~/.zfunc
