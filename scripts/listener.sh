#!/bin/bash

while read command; do
    echo "read '"$command"'"
done < <(nc -nlp 8888)

