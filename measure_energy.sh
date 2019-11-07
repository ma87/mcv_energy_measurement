#!/bin/bash
SOURCE_DIR="$(dirname "$PWD/$BASH_SOURCE")"
(return 0 2>/dev/null) && sourced=1 || sourced=0

measure_energy()
{
  use_battery_measurement=$1
  output_filename=$2
  cmd="$3"
  if [[ "$#" -gt "3" ]]; then 
    keys=$4
    number_keys=${#keys[@]}

    raw_keys=""
    raw_values=""

    for (( i=0; i<${number_keys}; i++ ));
    do
      raw_keys="$raw_keys""g|${keys[i]}\t"
      raw_values="$raw_values""${!keys[i]:-unassigned}\t"
    done

  else
    raw_keys=""
    raw_values=""
  fi
  raw_test="raw_data.tmp"
  if [[ $use_battery_measurement -eq "0" ]]; then
    ## MEASURE ENERGY USING TURBOSTAT
    sudo turbostat -S --quiet --Joules $cmd 2>&1 > /dev/null | tee $raw_test > /dev/null

    TIME_ELAPSED=$(awk '{if (NR==1) print $1}' $raw_test)
  
    # translate Pkg_J to ENERGY_CONSUMED
    sed -i 's/Pkg_J/ENERGY_CONSUMED/g' $raw_test

  else
    ## MEASURE ENERGY USING POWERTOP
    { sudo turbostat -S --quiet --Joules $SOURCE_DIR/measure_powertop.sh $SOURCE_DIR/powertop.csv $cmd ; } 2> $raw_test
    
    results=$(python3 $SOURCE_DIR/parse_powertop.py $SOURCE_DIR/powertop.csv $SOURCE_DIR/output_measure_time.txt)
    if [[ $? -gt "0" ]]; then
      echo "error during $SOURCE_DIR/parse_powertop.py"
      exit 1
    fi
    
    read -ra array_results <<< "$results"

    TIME_ELAPSED=${array_results[0]}
    ENERGY_CONSUMED=${array_results[1]}
    CPU_ENERGY_CONSUMED=${array_results[2]}

    raw_keys="$raw_keys""ENERGY_CONSUMED\tCPU_ENERGY_CONSUMED\t"
    raw_values="$raw_values""$ENERGY_CONSUMED\t$CPU_ENERGY_CONSUMED\t"

  fi

  ## Output results

  tail -n 3 $raw_test > tmp.txt
  mv tmp.txt $raw_test
  
  if [[ ! -e $output_filename ]]; then
        echo "create header for file " $output_filename
        awk -v keys="$raw_keys" '{if (NR==2) print keys "TIME_ELAPSED\t" $0}' $raw_test > $output_filename
  fi

  raw_data=$(awk '{if (NR==3) print $0}' $raw_test)

  if [[ ! -z $raw_values ]]; then
    echo -e "$raw_values$TIME_ELAPSED\t$raw_data" >> $output_filename
  else
    echo -e "$TIME_ELAPSED\t$raw_data" >> $output_filename
  fi
}

export -f measure_energy

## if executed as main
if [[ $sourced -eq 0 ]]; then
  if [[ "$#" -gt "2" ]]; then
    use_battery_measurement=$1
    output_filename=$2
    cmd="$3"
    keys=""
    if [[ "$#" -gt "3" ]]; then 
      shift 3
      read -ra keys <<< "$@"
    fi
    measure_energy $use_battery_measurement $output_filename "$cmd" $keys
    cat $output_filename
  else
    echo "not enough arguments"
    exit 1
  fi
fi
