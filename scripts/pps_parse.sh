#!/bin/bash

function pps_calc () {
	count=$(cat log/flow-dumps/$1 | grep tcp | awk 'BEGIN {count = 0}{ count = count + substr($4, 11, length($4)-11) } END {print count}')
	time=$(cat log/iperf3Client/$1 | jq '.end.sum_sent.seconds')

	echo $file-$(echo $count/$time | bc) >> ./pps.txt
}

rm ./pps.txt

while read file; do
        echo "file: "$file
        pps_calc $file
done <<< $(ls -1 log/flow-dumps/ | cut -d "." -f 1)
