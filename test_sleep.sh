#!/bin/bash


output_filename=`pwd`"/sleep_test_all_5.csv"

source measure_energy.sh

number_loops=20
sleep_times=(1 2 3 5 10)
for i in {1..20}; do
  for s in "${sleep_times[@]}"; do
    echo "$i -> $s"
    sleep_time=$s
    cmd="sleep $sleep_time"
    keys=("SLEEP_TIME")
    values=("$sleep_time")
    sleep 5
    measure_energy "$output_filename" "$cmd" $keys $values
  done
done

