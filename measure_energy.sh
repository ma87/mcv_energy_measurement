#!/bin/bash
SOURCE_DIR="$(dirname "$BASH_SOURCE")"

measure_energy()
{
  output_filename=$1
  cmd=$2
  if [[ "$#" -gt "2" ]]; then 
    keys=$3
    values=$4
    number_keys=${#keys[@]}
    number_values=${#values[@]}
    if [[ ! $number_keys -eq $number_values ]]; then
      return 1
    fi

    raw_keys=""
    raw_values=""

    for (( i=0; i<${number_keys}; i++ ));
    do
      raw_keys="$raw_keys""${keys[i]}\t"
      raw_values="$raw_values""${values[i]}\t"
    done

  else
    raw_keys=""
    raw_values=""
  fi

  raw_test="raw_data.tmp"
  sudo turbostat -S --quiet --Joules $cmd 2>&1 > /dev/null | tee $raw_test > /dev/null

  if [[ ! -e $output_filename ]]; then
        echo "file not exists"
        awk -v keys="$raw_keys" '{if (NR==2) print keys "TIME_ELAPSED\t" $0}' $raw_test > $output_filename
  fi

  time_elapsed=$(awk '{if (NR==1) print $1}' $raw_test)
  raw_data=$(awk '{if (NR==3) print $0}' $raw_test)

  if [[ ! -z $raw_values ]]; then
    echo -e "$raw_values$time_elapsed\t$raw_data" >> $output_filename
  else
    echo -e "$time_elapsed\t$raw_data" >> $output_filename
  fi
}

export -f measure_energy
