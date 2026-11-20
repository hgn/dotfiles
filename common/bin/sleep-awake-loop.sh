#!/usr/bin/env bash

# Cycles the machine between suspend-to-RAM and 10 seconds of uptime, to
# exercise the suspend path. Needs root, and the RTC alarm is what brings
# the system back up.

LOCK_NAME="loop_wakelock"
RTC="/sys/class/rtc/rtc0/wakealarm"

while true; do
    echo mem > /sys/power/autosleep

    # arm the wakeup before releasing the lock, otherwise the machine
    # suspends with no alarm set and stays down
    date +%s -d '+10 seconds' > "$RTC"
    echo "$LOCK_NAME" > /sys/power/wake_unlock

    echo "$LOCK_NAME" > /sys/power/wake_lock
    sleep 10
done
