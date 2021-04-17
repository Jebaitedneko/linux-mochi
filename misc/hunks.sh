#!/bin/sh -eu

# Taken from Artyom's reply over at https://unix.stackexchange.com/a/65703

PATCH=$1
OUTDIR=$2

test -f "$PATCH" && test -d "$OUTDIR"

TDIR=$(mktemp -d)
trap 'rm -rf $TDIR' 0

INDEX=0
TEMPHUNK=$TDIR/current_hunk

lsdiff $1 | while read FNAME
do
    HUNK=1
    while :
    do
        filterdiff --annotate --hunks=$HUNK -i "$FNAME" "$PATCH" > "$TEMPHUNK"
        HUNK=$((HUNK+1))
        test -s "$TEMPHUNK" && \
            {
                mv "$TEMPHUNK" "$OUTDIR/$INDEX.diff"
                INDEX=$((INDEX+1))
            } || break
    done
done
