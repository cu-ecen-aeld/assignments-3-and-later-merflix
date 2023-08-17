#!/usr/bin/bash

writefile=$1
writestr=$2


if [ $# != 2 ]; then
    echo "Not all parameters were given!"
    exit 1
fi

if ! mkdir -p "$(dirname "${writefile}")"; then
    echo "Path could not be created: $(dirname "${VAR}")"
fi

if ! touch "$writefile"; then
    echo "File could not be created: $writefile"
fi

echo "$writestr" > "$writefile"

