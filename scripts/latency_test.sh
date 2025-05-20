#!/bin/bash
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

verbose=1
stream_count=4
increment=3000
out="./pcaps"
pkt_size=512
srv_ip=10.0.0.1
rounds=1
iat=0.00001
round_size=65535 #65535 max
expected_round_time=$(echo $iat*$round_size | bc)

DuTs=(
#	xdp
#	napi
#	dpdk
)

declare -a experiments
for dut in "${DuTs[@]}"; do
for round in $(seq $rounds); do
	experiments+=($dut-$round)
done
done
experiments=( $(shuf -e "${experiments[@]}") )


log () {
	if (( verbose == 1 )); then
		echo $1
	fi
	
}

wait_for_iperf () {
	#printf "waiting for iperf server\n"
	while :; do
		ip netns exec client iperf3 -c $srv_ip -t 1 &> /dev/null
		if [ $? -eq 0 ]; then
			#printf "OK\n"
			break
		fi
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
	log "sending '$1'..."
	echo $1 | nc -N 10.10.10.1 8888
	while read command; do
		if [[ $command == "done" ]]; then 
			log "DuT change succeded"
		else
			echo $command >> ./log/flow-dumps/$2-$3-$4
		fi
	done < <(nc -nlp 8889)
	log "finished sending"
}

test () {
	iperfPID=""
	tcpdumpPID=""
	if [ $2 -ge 1 ]; then
		wait_for_iperf
		ip netns exec client iperf3 -c $srv_ip -t 86400 -b $(echo $2/$stream_count | bc)M -M$pkt_size -P $stream_count -J &>> ./log/iperf3Client/$1-$2-$3 &
		iperfPID=$!
	fi

	#bash -c "ip netns exec client sudo tcpdump -ni eno2 -w $out/$1-$2-$3.pcap -Us 60 -B 16384 -c $(echo 2*$round_size | bc) icmp &>> ./log_tcpdump &"
	ip netns exec client sudo tcpdump -ni eno2 -w $out/$1-$2-$3.pcap -Us 60 -B 16384 -c $(echo 2*$round_size | bc) icmp &>> ./log/tcpdump/$1-$2-$3 &
	tcpdumpPID=$!
	#waiting for tcpdump to start
	ip netns exec client sudo tcpdump -ni eno2 -w /dev/null -Us 60 -B 16384 -c 1 &> /dev/null

	/usr/bin/time -f "expected time: $expected_round_time actual time: %e" \
		ip netns exec client sudo python3 \
		/home/ecsvihus/2024-cnsm-5g-code/scripts/trafgen/5g-dp-client-v3.py \
		icmp det $iat small $round_size $srv_ip 6789 1 
	
	start_time=$(date +%s)
	while :; do
		sleep 0.5

		ps --pid=$tcpdumpPID &> /dev/null
		result=$?
		#if tcpdump is still running
		if [ ${result} -eq 1 ]; then
			#if experiment had background traffic
			if [ $2 -ge 1 ]; then
				kill_pid $iperfPID
				kill_pid $tcpdumpPID
				printf "\n"
				bps=$(sed '1d;$d' ./log/iperf3Client/$1-$2-$3 | jq '.end.sum_sent.bits_per_second')
				log "$1-$2-$3: "$(echo "scale=2;$bps/1024^3" | bc -l)"gbps"
			fi
			break
		fi

		now=$(date +%s)
		diff=$(echo $now-$start_time | bc) 
		if [ $diff -ge 5 ]; then
			printf "\n"
			echo "timeout"
			repeat=1
			if [ $2 -ge 1 ]; then
				kill_pid $iperfPID
				kill_pid $tcpdumpPID
			fi
			break
		else
			printf "*"
		fi
	done
}

ip netns exec server iperf3 -s >> ./log/iperf3Server &
serverPID=$!
sleep 2


if [[ $1 == "auto" ]]; then
echo "automatic"

repeat=0
for experiment in "${experiments[@]}"; do
	dut=$(echo $experiment | cut -d "-" -f 1)
	round=$(echo $experiment | cut -d "-" -f 2)


	echo $dut | nc -N 10.10.10.1 8888
	while read command; do
		if [[ "${string1}" != "${done}" ]]; then #FIXME
			echo "TODO: error handling"
		fi
	done < <(nc -nlp 8889)

	for traffic in $(seq 0 $increment 9000); do
		printf "running $dut at "$traffic"M round "$round"\n"
		while :; do
			repeat=0
			test $dut $traffic $round
			if [ $repeat -eq 0 ]; then
				break
			else
				echo "repeating"
			fi
		done
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
	test $dut $traffic $round
	change_dut dump $dut $traffic $round
done
	
else 
	echo "unkown mode"
	exit
fi




kill_pid ${serverPID}
