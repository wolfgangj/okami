#!/bin/sh

# 'cd' to load .gdbinit:
sh okcc.sh <boot.ok | ./ppok >script.ok && cd ../engine && gdb okami 3<../propulsion/script.ok
