#!/bin/bash

echo $1

for x in $1
do
	echo $x
done

tcpdump -r $1 2> /dev/null | tr ',' ' ' |
	awk '{a[$12] = a[$12] ? a[$12] FS $1 : $1} END {for (i in a) print a[i], i}' |
	awk '{
		split($1, t_1, ":");
		split($2, t_2, ":");
		
		start_us = t_1[1]*3600000000 + t_1[2]*60000000 + t_1[3]*1000000;
		end_us = t_2[1]*3600000000 + t_2[2]*60000000 + t_2[3]*1000000;
		diff_us = end_us-start_us

		printf "%s %i\n", $3, diff_us;
	}' > /dev/null
