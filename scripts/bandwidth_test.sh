#!/bin/bash

ip netns exec client iperf3 -c 10.0.0.1 -t 600 -M512 -P 4 -J > ./data/$1.json
