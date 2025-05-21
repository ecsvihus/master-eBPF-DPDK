#!/bin/bash

read -p "Change DuT to xdp, and then press enter: "
../../scripts/bandwidth_test.sh xdp
read -p "Change DuT to napi, and then press enter: "
../../scripts/bandwidth_test.sh napi
read -p "Change DuT to dpdk, and then press enter: "
../../scripts/bandwidth_test.sh dpdk
