#!/bin/bash

export DPDK_DIR=/home/ecsvihus/git-repos/dpdk-stable-23.11.2
export DPDK_BUILD=$DPDK_DIR/build
export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock

sudo sh -c 'echo 1 >i /sys/module/vfio/parameters/enable_unsafe_noiommu_mode'

#Starting OVS switcg
#sudo /usr/local/share/openvswitch/scripts/ovs-ctl start
#sudo ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
#sudo /usr/local/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start
