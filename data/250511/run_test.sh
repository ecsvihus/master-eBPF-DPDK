#!/bin/bash

rm -f ./pcaps/*
rm -f ./data/*
rm -f ./log/iperf3Server
rm -f ./log/iperf3Client/*
rm -f ./log/tcpdump/*
../../scripts/latency_test.sh
../../scripts/icmp_parse.sh
