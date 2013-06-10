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
export PATH=$HOME/bin:/sbin:/usr/sbin/:${PATH}

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
alias ls="ls --color=auto -T 0"
alias la="ls --color=auto -Al -T 0"
alias ll="ls --color -l -T 0"
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

alias ssh='ssh -c blowfish'

# use readline, completion and require rubygems by default for irb
# http://planetrubyonrails.org/show/feed/172
alias irb='irb --readline -r irb/completion -rubygems'
alias 3339date='date --rfc-3339=date'
alias freq="cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq"
alias pyclean='find . -type f -name "*.py[co]" -exec rm -f \{\} \;'

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'

[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

### check for OS
case $(uname -s) in 
  Linux)
    OS="linux"
    alias psa='ps axo "user,pid,ppid,%cpu,%mem,tty,stime,state,command"'
    # 0x20C3F4DD is my certification only key 
    alias gpgsign='gpg -u 20C3F4DD --sign-key'
  ;;
  *[bB][Ss][Dd])
    OS="bsd"
    alias psa='ps axo "user,pid,ppid,%cpu,%mem,tty,start,state,command"'
  ;;
  *)
    OS="unknown"
  ;; 
esac

### check for DIST
if [ -f /etc/redhat-release ]; then
  DIST="redhat"
elif [ -f /etc/debian_version ]; then
  DIST="debian"
elif [ -f /etc/gentoo-release ] || [ -f /usr/bin/emerge ]; then
  DIST="gentoo"
elif [ -f /etc/arch-release ]; then
  DIST="arch"
fi

case "${DIST}" in
  debian)
  ;;
  gentoo)
    #if [ -f /etc/profile.d/bash-completion ]; then
    #    source /etc/profile.d/bash-completion
    #fi
    export PATH=$PATH:/opt/java/jre/bin/
  ;;
  arch)
    export PATH=$PATH:/opt/java/jre/bin/
  ;;

  *)
  ;;
esac


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



# prompt
if test -z $SSH_TTY
then
  PROMPT=$'%{\e[01;36m%}@%m:%{\e[01;33m%}\%1~ %{\e[01;32m%}$%{\e[0m%} '
  [ $UID = 0 ] && export PROMPT=$'%{\e[0;31m%}[%{\e[0m%}%n%{\e[0;31m%}@%{\e[0m%}%m%{\e[0;31m%}:%{\e[0m%}%~%{\e[0;31m%}]%{\e[0m%}%# '
else
  PROMPT=$'%{\e[01;32m%}\%j,%{\e[01;36m%}%m,%{\e[01;34m%}%?,%{\e[01;33m%}\%1~ %{\e[01;32m%}$%{\e[0m%} '
  [ $UID = 0 ] && export PROMPT=$'%{\e[0;31m%}[%{\e[0m%}%n%{\e[0;31m%}@%{\e[0m%}%m%{\e[0;31m%}:%{\e[0m%}%~%{\e[0;31m%}]%{\e[0m%}%# '
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
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''


# of course
export EDITOR='/usr/bin/vim'

# favorite pager (give more information)
export PAGER='/usr/bin/less -M'

# work with history mechanism
HISTSIZE=20000
SAVEHIST=200000
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
  find . -iregex "${*}" -print
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

# if [ Now-Playing == "relaxmusic" ];then .. ;-)
beer()
{
  echo "         _.._..,_,_"
  echo "        (          )"
  echo "         ]~,\"-.-~~["
  echo "       .=])' (;  ([    Cheers!"
  echo "       | ]:: '    ["
  echo "       '=]): .)  (["
  echo "         |:: '    |"
  echo "          ~~----~~"
}

# gpg
function sgpg { gpg --keyserver pgp.mit.edu --search-key "$1"; }

# Process search
function psgrep {
    ps ax | grep $1 | fgrep -v "grep $1"
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
    echo "Usage: $0 [egofm | fm4 ]"
		return
  fi

	case $1 in
		fm4)
			mplayer -playlist http://mp3stream1.apasf.apa.at:8000/listen.pls
			;;
		egofm)
			mplayer http://www.egofm.de/stream/192kb
			;;
		*)
			echo "Usage: $0 [egofm | fm4 ]"
			;;
	esac
}




allulimit() {
  ulimit -c unlimited
  ulimit -d unlimited
  ulimit -f unlimited
  ulimit -l unlimited
  ulimit -n unlimited
  ulimit -s unlimited
  ulimit -t unlimited
}


# A quick globbing reference, stolen from GRML.
help-glob() {
echo -e "
/      directories
.      plain files
@      symbolic links
=      sockets
p      named pipes (FIFOs)
*      executable plain files (0100)
%      device files (character or block special)
%b     block special files
%c     character special files
r      owner-readable files (0400)
w      owner-writable files (0200)
x      owner-executable files (0100)
A      group-readable files (0040)
I      group-writable files (0020)
E      group-executable files (0010)
R      world-readable files (0004)
W      world-writable files (0002)
X      world-executable files (0001)
s      setuid files (04000)
S      setgid files (02000)
t      files with the sticky bit (01000)
print *(m-1)          # Dateien, die vor bis zu einem Tag modifiziert wurden.
print *(a1)           # Dateien, auf die vor einem Tag zugegriffen wurde.
print *(@)            # Nur Links
print *(Lk+50)        # Dateien die ueber 50 Kilobytes grosz sind
print *(Lk-50)        # Dateien die kleiner als 50 Kilobytes sind
print **/*.c          # Alle *.c - Dateien unterhalb von \$PWD
print **/*.c~file.c   # Alle *.c - Dateien, aber nicht 'file.c'
print (foo|bar).*     # Alle Dateien mit 'foo' und / oder 'bar' am Anfang
print *~*.*           # Nur Dateien ohne '.' in Namen
chmod 644 *(.^x)      # make all non-executable files publically readable
print -l *(.c|.h)     # Nur Dateien mit dem Suffix '.c' und / oder '.h'
print **/*(g:users:)  # Alle Dateien/Verzeichnisse der Gruppe >users<
echo /proc/*/cwd(:h:t:s/self//) # Analog zu >ps ax | awk '{print $1}'<"
  }


function netstate {
	netstat -tan | grep "^tcp" | cut -c 68- | sort | uniq -c | sort -n
}


alias calc="noglob _calc" calcfx="noglob _calcfx"
function _calc () {
             awk "BEGIN { print $* ; }"
}

function _calcfx () {
            gawk -v CONVFMT="%12.2f" -v OFMT="%.9g"  "BEGIN { print $* ; }"
}

eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'


# vim:set ts=2 tw=80 ft=zsh:
