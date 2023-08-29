#!/bin/sh

# check argument count
if [ $# -ne 2 ]
then
	echo "ERROR: wrong number of arguments, next to shell script name the file directory and searchstring must be given."
	exit 1
fi

# check if given string is a directory

if [ ! -d $1 ]
then
	echo "ERROR: given string is not a directory: $1"
fi 

# count number searchstring hits in total
echo "(grep -r -c $2 $1 | wc -l)"
hitcount=$(grep -r -c $2 $1 | wc -l)
# count number of files containing the string
echo "(find $1 -type f -print0 | xargs -0 grep -l $2 | wc -l)"
filecount=$(find $1 -type f | wc -l)

echo "The number of files are $filecount and the number of matching lines are $hitcount"
