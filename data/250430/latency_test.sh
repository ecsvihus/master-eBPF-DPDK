#!/bin/bash

out="./pcaps"
pkt_size=512
srv_ip=10.0.0.1
iat=0.01

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

count=100000
round_size=65535
rounds=10
DuTs=(
	dpdk
	napi
	xdp
)

declare -a experiments
for dut in "${DuTs[@]}"; do
for round in $(seq $rounds); do
	experiments+=($dut-$round)
done
done
experiments=( $(shuf -e "${experiments[@]}") )

test () {
	iperfPID=""
	tcpdumpPID=""
	if [ $2 -ge 1 ]; then
		wait_for_iperf
		ip netns exec client iperf3 -c $srv_ip -t 86400 -b $2M -M$pkt_size &> ./log &
		iperfPID=$!
		sleep 0.5
	fi
	sudo ip netns exec client sudo tcpdump -ni eno2 icmp -w $out/$1-$2-M.pcap &
	tcpdumpPID=$!
	sleep 0.5

	sudo ip netns exec client sudo python3 \
		/home/ecsvihus/2024-cnsm-5g-code/scripts/trafgen/5g-dp-client-v3.py \
		icmp det $iat small $count $srv_ip 6789 1


	if [ $2 -ge 1 ]; then
		kill $iperfPID
		kill $tcpdumpPID
	fi
}

wait_for_iperf () {
	echo "waiting for iperf server"
	while :; do
		ip netns exec client iperf3 -c $srv_ip -t 1 &> /dev/null
		if [ $? -eq 0 ]; then
			echo "OK"
			break
		fi
	done
}



ip netns exec server iperf3 -s &> ./log &
serverPID=$!

for dut in "${DuTs[@]}"; do
	#read -p "Change DuT to $dut, and then press enter: "

#	echo $dut | nc -N 10.10.10.1 8888
#	while read command; do
#    	echo "read '"$command"'"
#		if [[ "${string1}" != "${done}" ]]; then
#			echo "TODO: error handling"
#		fi
#	done < <(nc -nlp 8889)

	for i in {0..5000..1000}; do
		echo "running $dut at "$i"M"
		#test $dut $i
	done
done

kill $serverPID
