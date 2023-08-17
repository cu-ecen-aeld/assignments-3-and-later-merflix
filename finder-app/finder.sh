#!/usr/bin/bash
# p2

filesdir=$1
searchstr=$2

if [ $# != 2 ]; then
    echo "Not all parameters were given!"
    exit 1
fi

if [ ! -d "$filesdir" ]; then
    echo "Not a valid path: $filesdir"
    exit 1
fi

nof_expressions=$(grep -Ir "$searchstr" "$filesdir" | wc -l)
nof_files=$(grep -Ir "$searchstr" "$filesdir" | cut -d ':' -f 1 | uniq -c | wc -l)

echo "The number of files are $nof_files and the number of matching lines are $nof_expressions"

