#!/bin/bash

# Read absolute path of the script to be able to run subscripts
SOURCE_DIR="$(dirname "$PWD/$BASH_SOURCE")"

# Detect if script has been sourced or run as main
(return 0 2>/dev/null) && sourced=1 || sourced=0

## HELPER
show_help()
{
  echo "usage of measure_energy: measure_energy \$USE_BATTERY_MEASUREMENT \$OUTPUT_FILENAME \$CMD \$KEYS"
  echo "arguments are :
        USE_BATTERY_MEASUREMENT: if set to 1, use powertop to measure energy consumption. else turbostat --Joules is used
        OUTPUT_FILENAME: name of the output csv file
        CMD: command containing workload that we want to measure the energy consumption of.
        KEYS: list of extra information we want to add in the output csv file.
       "
}

measure_energy()
{
  if [[ "$#" -lt "3" ]]; then 
    show_help
    exit 1
  else
    use_battery_measurement=$1
    output_filename=$2
    cmd="$3"
  fi
  if [[ "$#" -gt "3" ]]; then 
    # keys is given by a list of argument
    # we need to convert it to an array
    shift 3
    read -ra keys <<< "$@"

    number_keys=${#keys[@]}

    raw_keys=""
    raw_values=""

    # Keys have been given to add extra information to the measures
    # key is a name of a variable that has been initialized before calling measure_energy
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

    # Turbostat can output some logs in the first lines, keep only the 3 last lines
    tail -n 3 $raw_test > tmp.txt
    mv tmp.txt $raw_test

    # turbostat first line corresponds to TIME_ELAPSED sec
    TIME_ELAPSED=$(awk '{if (NR==1) print $1}' $raw_test)
  
    # translate Pkg_J to ENERGY_CONSUMED
    sed -i 's/Pkg_J/ENERGY_CONSUMED/g' $raw_test

  else
    ## MEASURE ENERGY USING POWERTOP
    { sudo turbostat -S --quiet --Joules $SOURCE_DIR/measure_powertop.sh $SOURCE_DIR/powertop.csv $cmd ; } 2> $raw_test
   
    # Turbostat can output some logs in the first lines, keep only the 3 last lines
    tail -n 3 $raw_test > tmp.txt
    mv tmp.txt $raw_test
 
    # Parse files written by last command 
    results=$(python3 $SOURCE_DIR/parse_powertop.py $SOURCE_DIR/powertop.csv $SOURCE_DIR/output_measure_time.txt)
    if [[ $? -gt "0" ]]; then
      echo "error during $SOURCE_DIR/parse_powertop.py"
      exit 1
    fi
    
    # Convert output of python script to an array
    read -ra array_results <<< "$results"

    TIME_ELAPSED=${array_results[0]}
    # ENERGY_CONSUMED is computed by summing energy consumption of the processes found in powertop.csv
    ENERGY_CONSUMED=${array_results[1]}
    # CPU_ENERGY_CONSUMED is the harware cpu measure by powertop in powertop.csv
    CPU_ENERGY_CONSUMED=${array_results[2]}

    raw_keys="$raw_keys""ENERGY_CONSUMED\tCPU_ENERGY_CONSUMED\t"
    raw_values="$raw_values""$ENERGY_CONSUMED\t$CPU_ENERGY_CONSUMED\t"
  fi

  ## Output results
    
  # Create header if first data is written to output_filename 
  # Header corresponds to the extra information given by caller, TIME_ELAPSED and all information measured by turbostat
  if [[ ! -e $output_filename ]]; then
        echo "create header for file " $output_filename
        awk -v keys="$raw_keys" '{if (NR==2) print keys "TIME_ELAPSED\t" $0}' $raw_test > $output_filename
  fi

  # Get all data measured by turbostat
  raw_data=$(awk '{if (NR==3) print $0}' $raw_test)

  # Add data given by caller and TIME_ELAPSED
  if [[ ! -z $raw_values ]]; then
    echo -e "$raw_values$TIME_ELAPSED\t$raw_data" >> $output_filename
  else
    echo -e "$TIME_ELAPSED\t$raw_data" >> $output_filename
  fi
}

if [[ $sourced -eq 1 ]]; then
  # if sourced, measure_energy function is exported to be call by parent script
  export -f measure_energy
else
  ## if executed as main
  if [[ "$#" -gt "2" ]]; then
    use_battery_measurement=$1
    output_filename=$2
    cmd="$3"
    keys=""
    if [[ "$#" -gt "3" ]]; then 
      # keys is given by a list of argument
      # we need to convert it to an array
      shift 3
      read -ra keys <<< "$@"
    fi

    measure_energy $use_battery_measurement $output_filename "$cmd" $keys
    cat $output_filename
  else
    show_help
    exit 1
  fi
fi
