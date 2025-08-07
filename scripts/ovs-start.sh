#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

ip a add 10.10.10.1/24 dev eno3
ip link set up dev eno3

modprobe vfio-pci
/usr/bin/chmod a+x /dev/vfio
/usr/bin/chmod 0666 /dev/vfio/*


cd /home/ecsvihus/ovs
export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
sudo ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock     --remote=db:Open_vSwitch,Open_vSwitch,manager_options     --pidfile --detach --log-file
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start
