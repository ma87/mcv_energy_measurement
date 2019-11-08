#!/bin/bash


output_filename=`pwd`"/sleep_test_all_5.csv"

source measure_energy.sh

number_loops=2
sleep_times=(1 2 3 5 10)
for (( number_loop=0; number_loop<${number_loops}; number_loop++ )); do
  for s in "${sleep_times[@]}"; do
    echo "$number_loop -> $s"
    SLEEP_TIME=$s
    cmd="sleep $SLEEP_TIME"
    keys="SLEEP_TIME"
    sleep 5
    measure_energy 0 "$output_filename" "$cmd" $keys 
  done
done

