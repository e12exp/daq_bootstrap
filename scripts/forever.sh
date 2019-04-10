#!/bin/bash
echo "running forever:" "$@"
while true;
do
    echo running "$@"
    "$@"
    echo "command finished with value $?, restarting in 10s"
    sleep 10
done
