#!/bin/sh
# Find out the number of a C constant.
# Usage example: sh const.sh amd64/apmvar.h APM_IOC_GETPOWER 

cat >/tmp/wok-const.c <<EOF
#include <stdio.h>
#include <$1>

int main() {
    long x = $2 ;
    printf("unsigned:%lu\nsigned:%ld\nhex:0x%lx\n", x, x, x);
}
EOF
cc -o /tmp/wok-const /tmp/wok-const.c && /tmp/wok-const
