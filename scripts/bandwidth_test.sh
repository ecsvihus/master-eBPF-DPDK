#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

if [ -z "${4}" ]; then
	echo "Bad Arguments, command usage:"
	echo "bandwidth_test.sh <mode> <round_length> <rounds> <comma separated list of DuTs>"
	echo "example:"
	echo "bandwidth_test.sh auto 60 10 1400 xdp,napi,dpdk"
	exit 2
fi

# Variable definition

pid=$$
verbose=1
stream_count=24
pkt_sizes="88 216 472 984 1240"
srv_ip=10.0.0.1
rounds=$3
round_length=$2

DuTs=$4

declare -a experiments
for dut in $(echo $DuTs | tr ',' ' '); do
for round in $(seq $rounds); do
	experiments+=($dut-$round)
done
done
experiments=( $(shuf -e "${experiments[@]}") )


# Functions

log () {
	echo 	
	if (( verbose == 1 )); then
		echo $1
	fi
	
	echo $(ps -p $pid -o etimes=)"  $1" >> ./log/main
}

wait_for_iperf () {
	#printf "waiting for iperf server\n"
	while :; do
		ip netns exec client iperf3 -c $srv_ip -t 1 &> /dev/null
		if [ $? -eq 0 ]; then
			#printf "OK\n"
			break
		fi
		echo "iperf not ready"
	done
}

kill_pid () {
	while :; do
		sleep 0.5
		kill $1 &> /dev/null
		if [ $? -eq 1 ]; then
			break
		fi
	done
}

change_dut () {
	#log "sending '$1'..."
	echo $1 | nc -N 10.10.10.1 8888
	#log "sent"
	while read command; do
		if [[ $command == "done" ]]; then 
			echo "DuT change succeded"
		else
			echo $command >> ./log/flow-dumps/$2-$3-$4
		fi
	done < <(nc -nlp 8889)
	#log "finished sending"
}

recieve () {
	#log "sending '$1'..."
	echo $1 | nc -N 10.10.10.1 8888
	#log "sent"
	while read command; do
		echo $command
	done < <(nc -nlp 8889)
	#log "finished sending"
}

test () {
  wait_for_iperf
	change_dut cpustart
	sleep 30
	base=$(recieve cpuend)
#	echo "base=$base"

	change_dut cpustart
	ip netns exec client iperf3 -c $srv_ip \
		-b 0 -M$2 -P $stream_count -t $round_length -J -i 60 \
		&>> ./log/iperf3Client/$1-$2-$3
	load=$(recieve cpuend)
	#echo "load=$load"

	cpu_usage=$(echo $load-$base | bc)
	echo "cpu usage:$cpu_usage"

  bps=$(cat ./log/iperf3Client/$1-$2-$3 |\
		jq '.end.sum_sent.bits_per_second')
  #log "bps: $bps"
	log "$1-$2-$3,base=$base,load=$load,bps=$bps"
  echo "$1-$2-$3:$bps,$cpu_usage" >> ./data.txt
	change_dut dump $1 $2 $3
	echo "------------------------------"
}

#Main code

ip netns exec server iperf3 -s >> ./log/iperf3Server &
serverPID=$!
sleep 2


if [[ $1 == "auto" ]]; then
echo "automatic"

for experiment in "${experiments[@]}"; do
	dut=$(echo $experiment | cut -d "-" -f 1)
	round=$(echo $experiment | cut -d "-" -f 2)

	change_dut $dut
	for pkt in $pkt_sizes; do
#		log "running $dut at $pkt KB round $round"
		test $dut $pkt $round
	done
done


elif [[ $1 == "manual" ]]; then
echo "manual"
while :; do
	read -p "DuT:"
	dut=$REPLY
	read -p "traffic:"
	traffic=$REPLY
	read -p "round:"
	round=$REPLY
	change_dut $dut
	read -p "press enter to start"
	test $dut $traffic $round $pkt_size
	change_dut dump $dut $traffic $round
	#time=$(date +t%H%M%S)
	#change_dut napi
	#test napi 10000 $time
	#change_dut dump napi 10000 $time
done
	
else 
	echo "unkown mode"
	exit
fi




kill_pid ${serverPID}
