#!/bin/sh
# PreProcessor that replaces C constants

while read line; do
    if [ -n "$(echo "$line" | grep -E '^{.+:.+}$')" ]; then
        echo $(sh const.sh $(echo "$line" | sed -E -e 's/\{//' -e 's/}//' -e 's/:/.h /'))
    else
        echo "$line"
    fi
done
