#!/bin/sh

if [ -n "$2" ]; then
    EXPECTED="$2"
else
    EXPECTED=0
fi

sh ../propulsion/okcc.sh <"$1".ok | ../propulsion/ppok >/tmp/okami-step"$1".ok || exit 1
../engine/okami 3</tmp/okami-step"$1".ok

if [ "$?" = "$EXPECTED" ]; then
    echo "$1 ok"
else
    echo "$1 fail: got $? / expected $EXPECTED"
fi
