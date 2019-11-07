#!/bin/bash
SOURCE_DIR="$(dirname "$BASH_SOURCE")"

measure_energy()
{
  use_battery_measurement=$1
  output_filename=$2
  cmd=$3
  if [[ "$#" -gt "3" ]]; then 
    keys=$4
    values=$5
    number_keys=${#keys[@]}
    number_values=${#values[@]}
    if [[ ! $number_keys -eq $number_values ]]; then
      return 1
    fi

    raw_keys=""
    raw_values=""

    for (( i=0; i<${number_keys}; i++ ));
    do
      raw_keys="$raw_keys""g|${keys[i]}\t"
      raw_values="$raw_values""${values[i]}\t"
    done

  else
    raw_keys=""
    raw_values=""
  fi
  
  raw_test="raw_data.tmp"
  if [[ $use_battery_measurement -eq "0" ]]; then
    ## MEASURE ENERGY USING TURBOSTAT
    sudo turbostat -S --quiet --Joules $cmd 2>&1 > /dev/null | tee $raw_test > /dev/null

    tail -n 3 $raw_test > $raw_test
    time_elapsed=$(awk '{if (NR==1) print $1}' $raw_test)
  
  else
    ## MEASURE ENERGY USING POWERTOP
    { sudo turbostat -S --quiet $SOURCE_DIR/measure_powertop.sh $SOURCE_DIR/report.csv $cmd ; } 2> $raw_test
    
    results=$(python3 $SOURCE_DIR/parse_powertop.py $SOURCE_DIR/report.csv $SOURCE_DIR/output_measure_time.txt)
    if [[ $? -gt "0" ]]; then
      echo "error during $SOURCE_DIR/parse_powertop.py"
      exit 1
    fi
    
    read -ra array_results <<< "$results"

    time_elapsed=${array_results[0]}
    energy_consumed=${array_results[1]}
    cpu_energy_consumed=${array_results[2]}

  fi

  raw_keys="$raw_keys""ENERGY_CONSUMED\tCPU_ENERGY_CONSUMED\t"
  raw_values="$raw_values""$energy_consumed\t""$cpu_energy_consumed\t"

  ## Output results

  tail -n 3 $raw_test > tmp.txt
  mv tmp.txt $raw_test

  if [[ ! -e $output_filename ]]; then
        echo "file not exists"
        awk -v keys="$raw_keys" '{if (NR==2) print keys "TIME_ELAPSED\t" $0}' $raw_test > $output_filename
  fi

  raw_data=$(awk '{if (NR==3) print $0}' $raw_test)

  if [[ ! -z $raw_values ]]; then
    echo -e "$raw_values$time_elapsed\t$raw_data" >> $output_filename
  else
    echo -e "$time_elapsed\t$raw_data" >> $output_filename
  fi
}

export -f measure_energy

