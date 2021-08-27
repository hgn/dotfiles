
xrdb -merge ~/.Xdefaults

eval `ssh-agent`
eval $(gpg-agent --daemon)

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

pidgin &

xinput set-prop "pointer:Logitech MX Master" "Coordinate Transformation Matrix" 4.000000, 0.000000, 0.000000, 0.000000, 4.000000, 0.000000, 0.000000, 0.000000, 1.000000

exec /usr/bin/awesome
