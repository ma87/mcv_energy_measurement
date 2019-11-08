# mcv_energy_measurement

## Linux

2 tools are used to measure energy consumption by software running on Linux:

* turbostat (source available [here](https://github.com/torvalds/linux/blob/master/tools/power/x86/turbostat/turbostat.c) : use RAPL to measure energy consumption by cpu over time
* powertop (source [here](https://github.com/fenrus75/powertop) : can use RAPL and battery to measure energy consumption. Here we use it with battery mode. It needs calibration to be able to measure energy consumption, you have to run 

powertop --calibrate

and then when running powertop, as stated in [documentation](https://01.org/sites/default/files/page/powertop_users_guide_201412.pdf): PowerTOP needs to execute for a minimal number oftimes to allow a good fitness modelcalculation. After version 2.7 PowerTOP shows the required number of times to execute along with the number of measurements that already accumulated. The data is stored on saved\_parameters.powertop and saved\_results.powertopboth under /var/cache/powertop/. 

To speed things up one could execute a bash program that runs PowerTOP for the required number of times.

for (i=0; i < minimum\_runs; i++)
  sudo powertop –time=10 --html

## Windows

Integration of [Intel Power Gadget library](https://software.intel.com/en-us/articles/intel-power-gadget/) to get RAPL measurements through windows API. Work in progress...
