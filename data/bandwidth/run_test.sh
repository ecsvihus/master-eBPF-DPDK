#!/bin/bash

rm -f ./log/main
rm -f ./log/iperf3Server
rm -f ./log/iperf3Client/*
rm -f ./log/flow-dumps/*
rm -f ./data.txt
../../scripts/bandwidth_test.sh auto 300 5 napi,xdp1,dpdk
#../../scripts/bandwidth_test.sh auto 60 3 xdp1,xdp2,xdp3,napi,dpdk
#../../scripts/icmp_parse.sh
