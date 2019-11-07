#!/bin/bash

SOURCE_DIR="$(dirname "$BASH_SOURCE")"

{ time $@ > /dev/null ; } 2> $SOURCE_DIR/output_measure_time.txt

