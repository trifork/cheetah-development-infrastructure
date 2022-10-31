#!/bin/bash

while [ true ]
do
    echo "Command: $@"
    $@ || true
    echo "Sleeping 60"
    sleep 60
done
