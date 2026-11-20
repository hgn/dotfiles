#!/bin/bash

check_success() {
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] $1"
    else
        echo "[ERROR] $2"
        exit 1
    fi
}

echo -n "Remounting /sys/kernel/tracing... "
sudo mount -o remount,rw,mode=755 /sys/kernel/tracing &> /dev/null
check_success "Remounted" "Failed to remount"

echo -n "Exposing kernel pointers... "
echo "0" | sudo tee /proc/sys/kernel/kptr_restrict &> /dev/null
check_success "Done" "Failed to expose kernel pointers"

echo -n "Enabling system-wide profiling... "
echo "-1" | sudo tee /proc/sys/kernel/perf_event_paranoid &> /dev/null
check_success "Done" "Failed to enable system-wide profiling"

echo -n "Changing ownership of uprobe_events... "
sudo chown $(whoami) /sys/kernel/tracing/uprobe_events &> /dev/null
check_success "Done" "Failed to change ownership"

echo -n "Setting permissions for uprobe_events... "
sudo chmod a+rw /sys/kernel/tracing/uprobe_events &> /dev/null
check_success "Done" "Failed to set permissions"
