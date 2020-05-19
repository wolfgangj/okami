#!/bin/sh
# Find out the number of an ioctl call.
# Usage example: sh ioctl.sh amd64/apmvar.h APM_IOC_GETPOWER 

cat >/tmp/wok-ioctl.c <<EOF
#include <stdio.h>
#include <$1>

int main() {
    printf("%lu\n", $2);
}
EOF
cc -o /tmp/wok-ioctl /tmp/wok-ioctl.c && /tmp/wok-ioctl
