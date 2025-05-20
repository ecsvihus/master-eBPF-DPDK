#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

function stop () {
	echo "deleting ports"
	ovs-vsctl --if-exists del-port br1 eno1
	ovs-vsctl --if-exists del-port br1 eno2
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
}

function flows () {
	ovs-vsctl list-br | xargs -L1 sudo ovs-ofctl del-flows
	ovs-ofctl add-flow $1 "tcp,in_port=eno1, actions=output:eno2"
	ovs-ofctl add-flow $1 "tcp,in_port=eno2, actions=output:eno1"
	ovs-ofctl add-flow $1 "icmp,in_port=eno1, actions=output:eno2"
	ovs-ofctl add-flow $1 "icmp,in_port=eno2, actions=output:eno1"
	ovs-ofctl add-flow $1 "arp,in_port=eno1, actions=output:eno2"
	ovs-ofctl add-flow $1 "arp,in_port=eno2, actions=output:eno1"
}

function dpdk () {
	modprobe vfio-pci
	/usr/bin/chmod a+x /dev/vfio
	/usr/bin/chmod 0666 /dev/vfio/*
	ip a flu eno1
	ip a flu eno2

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

	flows br1
}

function napi () {
	sudo ip link set up dev eno1
	sudo ip link set up dev eno2
    ovs-vsctl add-br br1
	ovs-vsctl add-port br1 eno1
    ovs-vsctl add-port br1 eno2
	flows br1
}

function xdp () {
	echo "starting"

	sudo ip link set up dev eno1
	sudo ip link set up dev eno2

	ovs-vsctl -- add-br br1 -- set bridge br1 datapath_type=netdev

#	ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0x30
	#ovs-vsctl set Open_vSwitch . other_config:pmd-rxq-isolate=false

        ethtool -L eno1 combined 1
	ovs-vsctl add-port br1 eno1 -- set interface eno1 type="afxdp" \
		options:xdp-mode=best-effort
#		other_config:pmd-rxq-affinity="0:4,1:5"

	ethtool -L eno2 combined 1	
        ovs-vsctl add-port br1 eno2 -- set interface eno2 type="afxdp" \
		options:xdp-mode=best-effort 
#		other_config:pmd-rxq-affinity="0:6,1:7"

	flows br1
}


function auto () {
	while read command; do
    	echo "read '"$command"'"
		if [ "$command" == "dpdk" ]; then
			stop
			dpdk
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "napi" ]; then
			stop
			napi
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "xdp" ]; then
			stop
			xdp
			echo "done" | nc -N 10.10.10.2 8889
			echo "done"
		elif [ "$command" == "dump" ]; then
			#sometimes command output is empty
			declare dump
			while [[ -z $dump ]]; do
				dump=$(ovs-ofctl dump-flows br1)
				sleep 0.5
			done

			echo "$dump" | nc -N 10.10.10.2 8889
			echo "done"
		fi
	done < <(nc -nklp 8888)
}


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
