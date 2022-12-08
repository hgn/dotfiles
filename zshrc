# Hagen Paul Pfeifer - hagen@jauu.net
# http://www.jauu.net

setopt HIST_VERIFY

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

# default encrypted session via rsync
export RSYNC_RSH=ssh

# Language Stuff
# english messages && time, utf8 support
export LC_ALL=de_DE.utf8
export LANGUAGE=C
export LANG=C
export LC_MESSAGES=C
export LC_TIME=C
export LC_CTYPE=de_DE.utf8


## ALIASES

alias mutt-offline='mutt -F ~/.mutt/muttrc-offline'

alias bat='batcat -pp'

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

alias fd=fdfind

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
HISTORY_IGNORE="(ls|ll|rm|fg|cd|pwd|exit|cd ..)"

# use z, with menu
source ~/.zsh-z.plugin.zsh
zstyle ':completion:*' menu select

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

# cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# turns off spelling correction for commands
setopt nocorrect
# ORRECTALL option turns on spelling correction for all arguments
setopt nocorrectall

# ignore duplicated entrys in history and with trailing spaces
setopt histignoredups
setopt histignorespace

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
setopt HIST_VERIFY      # Make those history commands nice
setopt NO_BEEP          # self explanatory
setopt AUTO_NAME_DIRS   # change directories  to variable names
setopt CHASE_LINKS      # if you pwd from a symlink, you get the actual path
setopt AUTO_CONTINUE    # automatically sent a CONT signal by disown
setopt LONG_LIST_JOBS   # List jobs in the long format by default

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_NO_FUNCTIONS
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



PROMPT=$'%{\e[01;33m%}\%1~ %{\e[01;32m%}$%{\e[0m%} '

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
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''


# of course
export EDITOR='/usr/bin/vim'

# favorite pager (give more information)
export PAGER='/usr/bin/less -M'

# work with history mechanism
HISTSIZE=200000
SAVEHIST=2000000
HISTFILE=~/.zhistory


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


# the following funtion found on http://status.deifl-web.de/dotfiles/zsh/zshfunctions

# mkdir && cd
function mcd() { mkdir "$@"; cd "$@" }

# cd && ls
function cl() { cd $1 && ls -l }

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
  # lkml stuff
  notmuch new
	notmuch tag +lkml +list folder:Lists.lkml
	notmuch tag +keep -- tag:lkml and to:hagen.pfeifer@jauu.net
	notmuch tag +keep -- tag:lkml and subject:perf
	notmuch tag +keep -- tag:lkml and subject:trace
	# mark all messages older 1 month and not to me, not perf, trace as "killed"
	notmuch tag +killed -- tag:lkml and not tag:keep and date:..1month
}
function mail-cleanup () {
  echo "did you call mail-classify first?"
	echo "now will delete killed tagged email"
	notmuch search tag:killed
	notmuch search --output=files --format=text0 tag:killed | xargs --no-run-if-empty rm
  notmuch new
	offlineimap -o -u basic
}
function mail-sync-offline () {
	offlineimap -o -u basic
	mail-classify
	mail-cleanup
}

eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

source /usr/share/doc/fzf/examples/key-bindings.zsh
#source /usr/share/zsh/vendor-completions/_fzf
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --exact'

function email-sync {
	echo "Email Two-Way Synchronization Initiated"
	# I do not ping mailbox.org because I realized strange effects
	# for dual stack hosts during IPv6 SLAAC. Not sure if DSLite problem 
	if ! ping -c 1 heise.de >/dev/null 2>&1; then
    echo "Mailbox.org not pingable"
		return
  fi
	offlineimap -o -u ttyui
	notmuch new
	notmuch tag +linux-perf -- folder:Lists.lkml subject:perf or subject:trace
	echo "tips:"
	echo "    notmuch search thread:{tag:linux-perf}"
	echo "    notmuch search --sort oldest-first thread:{tag:linux-perf} date:1month..now"
	du -sh .mail
}

alias mutt-sync-offline='echo "Offline Mode";sleep 0.4;email-sync;mutt -F ~/.mutt/muttrc-offline; email-sync'
alias mutt-offline='mutt -F ~/.mutt/muttrc-offline'


# vim:set ts=2 tw=80 ft=zsh:

autoload -Uz compinit
fpath+=~/.zfunc
