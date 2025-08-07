#!/bin/bash

ctrlc_received=0

function handle_ctrlc()
{
	second=$(cat /proc/stat | head -n 1 | awk '{print $5}')
	stop=$EPOCHREALTIME

	cpu_diff=$(echo $second-$first | bc)
	time_diff=$(echo $stop-$start | bc)
	cpu=$(echo "scale=2; 100-(($cpu_diff / 28) / $time_diff)" | bc)

	echo $cpu
	exit
}

# trapping the SIGTERM signal
trap handle_ctrlc SIGTERM

first=$(cat /proc/stat | head -n 1 | awk '{print $5}')
start=$EPOCHREALTIME
while true
do 
        sleep 1
done




