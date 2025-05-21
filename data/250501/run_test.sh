#!/bin/bash

rm -f ./pcaps/*
rm -f ./data/*
rm log*
../../scripts/latency_test.sh
../../scripts/icmp_parse.sh
