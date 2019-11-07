#!/bin/bash

SOURCE_DIR="$(dirname "$BASH_SOURCE")"

filename=$1
shift
args=$@
{ sudo powertop -C $filename -i 1 -w "$SOURCE_DIR/measure_time.sh $args" ; } 2> $SOURCE_DIR/output_measure_powertop.txt

