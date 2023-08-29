#!/bin/sh

# check argument count
if [ $# -ne 2 ]
then
	echo "ERROR: wrong number of arguments, next to shell script name a full path to a file and searchstring must be given."
	exit 1
fi

#try to create file or update timestamp, first try to create directory if not existing
mkdir -p $(dirname $1)
touch $1

if [ ! -e $1 ]
then
	echo "ERROR: file could not be create, please check if it is a path: $1"
fi 

# write content to file
echo $2 > $1

