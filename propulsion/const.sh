#!/bin/sh
# Find out the number of a C constant.
# Usage example: sh const.sh amd64/apmvar.h APM_IOC_GETPOWER 

cat >/tmp/okami-const.c <<EOF
#include <stdio.h>
#include <$1>

int main() {
    long x = $2 ;
    printf("#%ld\n", x);
}
EOF
cc -o /tmp/okami-const /tmp/okami-const.c && /tmp/okami-const
