
xrdb -merge ~/.Xdefaults

eval `ssh-agent`
#eval $(gpg-agent --daemon) &
#eval $(gpg-agent --enable-ssh-support --daemon)

# Turn off beeps:
#xset -b
# keyboard repeat-rate:
xset r rate 195 35

#syndaemon -t -k -i 2 &

# favourite mouse cursor:
xsetroot -cursor_name right_ptr

setxkbmap us

# caps lock as compose key
#setxkbmap -option compose:caps

#xbindkeys 

xsetroot -solid "#101010"

#pidgin &

exec /usr/bin/awesome
