#!/bin/sh
if [ "$#" -ne 2 ] ; then
 echo "number of arguments shall be 2" >&2
 exit 1
fi
if ! [ -d  "$1" ]; then
     echo "$1  is not a directory" >&2
     exit 1
fi
find "$1" -type f | wc -l
find "$1" -type f | grep -Fo "$2" | wc -l
 x=$(find "$1" -type f | wc -l )
 y=$(grep -r "$2"  "$1" | wc -l )
echo "The number of files are $x and the number of matching lines are $y"

