#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

cpu_pid=999999

function stop () {
	echo "deleting ports"
	ovs-vsctl --if-exists del-port br1 eno1
	ovs-vsctl --if-exists del-port br1 eno2
	ovs-vsctl --if-exists del-port br1 NS-host
	echo "deleting bridge"
    ovs-vsctl --if-exists del-br br1


	ports=$(dpdk-devbind.py -s | grep drv=vfio-pci | awk '{print $1}')
	for x in ${ports}; do
		echo "unbinding $x"
		dpdk-devbind.py -u $x
		sleep 1
		dpdk-devbind.py --bind=ixgbe $x
		sleep 1
	done

	ovs-vsctl remove Open_vSwitch . other_config pmd-cpu-mask
}

function flows-ns () {
	ovs-vsctl list-br | xargs -L1 sudo ovs-ofctl del-flows
	ovs-ofctl add-flow $1 "tcp,in_port=NS-host, actions=output:eno2"
	ovs-ofctl add-flow $1 "tcp,in_port=eno2, actions=output:NS-host"
	ovs-ofctl add-flow $1 "icmp,in_port=NS-host, actions=output:eno2"
	ovs-ofctl add-flow $1 "icmp,in_port=eno2, actions=output:NS-host"
	ovs-ofctl add-flow $1 "arp,in_port=NS-host, actions=output:eno2"
	ovs-ofctl add-flow $1 "arp,in_port=eno2, actions=output:NS-host"
	ovs-ofctl add-flow $1 "udp,in_port=NS-host, actions=output:eno2"
        ovs-ofctl add-flow $1 "udp,in_port=eno2, actions=output:NS-host"
	ovs-ofctl add-flow $1 "in_port=NS-host, actions=output:eno2"
	ovs-ofctl add-flow $1 "in_port=eno2, actions=output:NS-host"
}

function flows () {
        ovs-vsctl list-br | xargs -L1 sudo ovs-ofctl del-flows
        ovs-ofctl add-flow $1 "tcp,in_port=eno1, actions=output:eno2"
        ovs-ofctl add-flow $1 "tcp,in_port=eno2, actions=output:eno1"
        ovs-ofctl add-flow $1 "icmp,in_port=eno1, actions=output:eno2"
        ovs-ofctl add-flow $1 "icmp,in_port=eno2, actions=output:eno1"
        ovs-ofctl add-flow $1 "arp,in_port=eno1, actions=output:eno2"
        ovs-ofctl add-flow $1 "arp,in_port=eno2, actions=output:eno1"
        ovs-ofctl add-flow $1 "udp,in_port=eno1, actions=output:eno2"
        ovs-ofctl add-flow $1 "udp,in_port=eno2, actions=output:eno1"
}

function dpdk () {
	modprobe vfio-pci
	/usr/bin/chmod a+x /dev/vfio
	/usr/bin/chmod 0666 /dev/vfio/*
	ip a flu eno1
	ip a flu eno2

	ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0xf

	ovs-vsctl add-br br1 -- set bridge br1 datapath_type=netdev
	echo "binding eno1"
	dpdk-devbind.py --bind=vfio-pci 0000:01:00.0
	sleep 1
	echo "binding eno2"
	dpdk-devbind.py --bind=vfio-pci 0000:01:00.1

	ovs-vsctl add-port br1 eno1 -- set interface eno1 \
		type=dpdk options:dpdk-devargs=0000:01:00.0
	ovs-vsctl add-port br1 eno2 -- set interface eno2 \
		type=dpdk options:dpdk-devargs=0000:01:00.1

	#ovs-vsctl add-port br1 NS-host
}

function napi () {
	sudo ip link set up dev eno1
	sudo ip link set up dev eno2
	ovs-vsctl add-br br1
	ovs-vsctl add-port br1 eno1
	ovs-vsctl add-port br1 eno2
	#ovs-vsctl add-port br1 NS-host
}

function xdp () {
	echo "starting"

	nrxq=$1
	mask=$2
	affinity_eno1=$3
	affinity_eno2=$4

	echo "->$nrxq<- ->$mask<- ->$affinity_eno1<- ->$affinity_eno2<-"
	sudo ip link set up dev eno1
	sudo ip link set up dev eno2

	ovs-vsctl -- add-br br1 -- set bridge br1 datapath_type=netdev

	ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$mask
	ovs-vsctl set Open_vSwitch . other_config:pmd-rxq-isolate=true

	ethtool -L eno1 combined $nrxq
	ovs-vsctl add-port br1 eno1 -- set interface eno1 type="afxdp" \
		options:n_rxq=$nrxq other_config:pmd-rxq-affinity="$affinity_eno1"
			#other_config:pmd-rxq-affinity="0:3"
#                other_config:pmd-rxq-affinity="0:3" options:xdp-mode=best-effort
#		options:xdp-mode=best-effort
#		other_config:pmd-rxq-affinity="0:4,1:5"

	ethtool -L eno2 combined $nrxq
        ovs-vsctl add-port br1 eno2 -- set interface eno2 type="afxdp" \
		options:n_rxq=$nrxq other_config:pmd-rxq-affinity="$affinity_eno2"
			#other_config:pmd-rxq-affinity="0:4"
#                other_config:pmd-rxq-affinity="0:4" options:xdp-mode=best-effort
#		options:xdp-mode=best-effort 
#		other_config:pmd-rxq-affinity="0:6,1:7"

#	ethtool -L eno2 combined 1
#	ovs-vsctl add-port br1 NS-host -- set interface NS-host type="afxdp" \
#		other_config:pmd-rxq-affinity="0:4"
}

function auto () {
	while read command; do
    	echo "read '"$command"'"
		if [ "$command" == "dpdk" ]; then
			stop
			dpdk
			flows br1
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "napi" ]; then
			stop
			napi
			flows br1
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "xdp1" ]; then
			stop
			xdp 1 0x3 0:0 1:1
			flows br1
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "xdp2" ]; then
                        stop
                        xdp 2 0xf 0:0,1:1 2:2,3:3
                        flows br1
                        echo "done" | nc -N 10.10.10.2 8889
                        echo "done"
		elif [ "$command" == "xdp3" ]; then
                        stop
                        xdp 3 0x3f 0:0,1:1,2:2 3:3,4:4,5:5
                        flows br1
                        echo "done" | nc -N 10.10.10.2 8889
                        echo "done"
		elif [ "$command" == "dpdkNS" ]; then
			stop
			dpdk
			flows-ns br1
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "napiNS" ]; then
			stop
                        napi
                        flows-ns br1
                        echo "done" | nc -N 10.10.10.2 8889
                        echo "done"
		elif [ "$command" == "xdpNS" ]; then
			stop
                        xdp
                        flows-ns br1
                        echo "done" | nc -N 10.10.10.2 8889
                        echo "done"
		elif [ "$command" == "cpustart" ]; then
			sudo rm -f /tmp/cpu
			/home/ecsvihus/master-eBPF-DPDK/scripts/cpu_usage.sh > /tmp/cpu &
			cpu_pid=$!
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "cpuend" ]; then
			kill -SIGTERM $cpu_pid
			sleep 1
			cpu=$(</tmp/cpu)
			echo $cpu | nc -N 10.10.10.2 8889
			echo $cpu
			echo "done"
		elif [ "$command" == "dump" ]; then
			#sometimes command output is empty
			declare dump=$(ovs-ofctl dump-flows br1)
			declare -i counter=0
			while [[ -z $dump ]]; do
				counter+=1
				echo "dump failed, trying again"
				dump=$(ovs-ofctl dump-flows br1)
				sleep 0.5
			done

			echo "$dump" | nc -N 10.10.10.2 8889
			echo "done"
			flows br1
		fi
	done < <(nc -nklp 8888)
}



#ip netns exec NS iperf3 -s &
#serverPID=$!
#sleep 2


mapfile -t pidsArr < <(pgrep ksoftirqd && pgrep "ovs-vswitchd")
pidsStr=$(echo "${pidsArr[*]}")


if [ "$1" == "dpdk" ]; then
	echo "starting DPDK"
	stop
	dpdk
elif [ "$1" == "napi" ]; then
	echo "starting NAPI"
	stop
	napi
elif [ "$1" == "xdp" ]; then
	echo "starting XPD"
	stop
	xdp
elif [ "$1" == "stop" ]; then
	echo "Stopping"
	stop
elif [ "$1" == "auto" ]; then
	echo "Automatic mode"
	auto
else
	echo "invalid command"
fi
