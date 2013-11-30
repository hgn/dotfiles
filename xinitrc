
xrdb -merge ~/.Xdefaults

eval `ssh-agent`

# Turn off beeps:
xset -b
# keyboard repeat-rate:
xset r rate 195 35

# favourite mouse cursor:
xsetroot -cursor_name right_ptr

setxkbmap us

# caps lock as compose key
setxkbmap -option compose:caps

pidgin &

exec /usr/bin/awesome
