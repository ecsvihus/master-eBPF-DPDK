#!/bin/bash

rm -f ./pcaps/*
rm -f ./data/*
rm log/iperf3Client/*
rm log/tcpdump/*
rm log/flow-dumps/*
rm log/iperf3Server

../../scripts/latency_test.sh manual
