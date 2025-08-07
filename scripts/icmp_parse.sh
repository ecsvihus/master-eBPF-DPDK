#!/bin/bash

in=$1
out=$2

if [[ -z "$in" ]]; then
	echo "assuming in=./pcaps"
	in="./pcaps"
fi
if [[ -z "$out" ]]; then
	echo "assuming out=./data"
	out="./data"
fi




function parse () {
	tcpdump -r $1 2> /dev/null | tr ',' ' ' |
	awk '{a[$12] = a[$12] ? a[$12] FS $1 : $1} END {for (i in a) print a[i], i}' |
	awk '{
		split($1, t_1, ":");
		split($2, t_2, ":");
		
		if (length($3) != 0) {
			start_us = t_1[1]*3600000000 + t_1[2]*60000000 + t_1[3]*1000000;
			end_us = t_2[1]*3600000000 + t_2[2]*60000000 + t_2[3]*1000000;
			diff_us = end_us-start_us;

			printf "%i\n", diff_us;	
		}

	}'
}





while read file; do
	echo "file: "$file
	parse $in/$file.pcap > $out/$file.data
done <<< $(ls -1 $in | cut -d "." -f 1)




