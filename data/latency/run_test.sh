#!/bin/bash

rm -f ./pcaps/*
rm -f ./data/*
rm -f ./log/iperf3Server
rm -f ./log/flow-dumps/*
rm -f ./log/tcpdump/*
rm -f ./log/iperf3Client/*
rm -f ./log/main
../../scripts/latency_test.sh auto 20000 3 1400 0.002 xdp1,xdp2,xdp3,napi,dpdk 10000
../../scripts/latency_test.sh auto 20000 3 150 0.002 xdp1,xdp2,xdp3,napi,dpdk 6000
#../../scripts/icmp_parse.sh
