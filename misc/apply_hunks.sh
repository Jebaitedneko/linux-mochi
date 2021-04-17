#!/bin/bash

# Taken from Shum's reply over at https://unix.stackexchange.com/a/65721

if [[ $# -ne 1 || ! -d "${1}/" ]]; then
    echo "Usage: $0 dirname"
    exit 1
fi

find "$1" -name \*.diff | while read f; do
    OUTPUT=$(patch -s -p1 -r- -i"$f")
    if [ $? -eq 0 ]; then
        rm "$f"
    else
        if echo "$OUTPUT" | grep -q "Reversed (or previously applied) patch detected!"; then
            rm "$f"
        fi
    fi
done
