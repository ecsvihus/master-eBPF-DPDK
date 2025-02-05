#!/bin/bash
export DPDK_DIR=/home/ecsvihus/dpdk-stable-23.11.2
export DPDK_BUILD=$DPDK_DIR/build
export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock


sudo sh -c 'echo 1 >i /sys/module/vfio/parameters/enable_unsafe_noiommu_mode'

#Adding interface to DPDK
#sudo ip ad flu eno3
#sudo $DPDK_DIR/usertools/dpdk-devbind.py --bind=vfio-pci 0000:01:00.1

#Starting OVS switcg
#sudo /usr/local/share/openvswitch/scripts/ovs-ctl start
#sudo ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
#sudo /usr/local/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start

#Adding DPDK interface to OVS
#sudo ovs-vsctl add-port br0 eno3 -- set Interface eno3 type=dpdk options:dpdk-devargs=0000:01:00.1

#Adding Flows to OVS switch
#sudo ovs-ofctl del-flows br0
