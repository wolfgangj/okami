#!/bin/sh
# PreProcessor that replaces C constants

while read -r line; do
    if [ -n "$(printf "%s\n" "$line" | grep -E '^{.+:.+}$')" ]; then
        echo $(sh ../propulsion/const.sh $(echo "$line" | sed -E -e 's/\{//' -e 's/}//' -e 's/:/.h /'))
    else
        printf "%s\n" "$line"
    fi
done
