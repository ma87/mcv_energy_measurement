import sys
import re

if len(sys.argv) <= 2:
    exit(1)

filename_powertop = sys.argv[1]
filename_time     = sys.argv[2]


total_power = 0.0
time_elapsed = 0.0
cpu_use = 0.0

with open(filename_powertop, 'r', encoding="utf8", errors='ignore') as f:
    consume_reg_exp = re.compile(r'\s*(\d+).?(\d*) (\w*)')
    contents = f.readlines()
    start_parsing = False
    for l in contents:
        if not start_parsing and "Top 10 Power Consumers" in l:
            start_parsing = True
        if start_parsing:
            if "__________" in l:
                start_parsing = False
                break
            else:
                elems = l.split(';')
                if len(elems) >= 3 and elems[2] == "Process":
                    entire_part, dec_part, units = tuple(consume_reg_exp.match(elems[-1]).groups())

                    if units == "mW":
                        factor = 1e3
                    elif units == "uW":
                        factor = 1e6
                    else:
                        factor = 1

                    total_power += float(entire_part + "." + dec_part) / factor

with open(filename_powertop, 'r', encoding="utf8", errors='ignore') as f:
    consume_reg_exp = re.compile(r'\s*(\d+).?(\d*) (\w*)')
    contents = f.readlines()
    start_parsing = False
    for l in contents:
        if not start_parsing and "Device Power Report" in l:
            start_parsing = True
        if start_parsing:
            if "__________" in l:
                start_parsing = False
                break
            else:
                elems = l.split(';')
                if len(elems) >= 3 and elems[1] == "CPU use":
                    entire_part, dec_part, units = tuple(consume_reg_exp.match(elems[-1]).groups())

                    if units == "mW":
                        factor = 1e3
                    elif units == "uW":
                        factor = 1e6
                    else:
                        factor = 1

                    cpu_use = float(entire_part + "." + dec_part) / factor
                    break
 

with open(filename_time, 'r') as f:
    time_reg_exp = re.compile(r'(\d+)m(\d+).?(\d*)s')
    contents = f.readlines()
    for l in contents:
        elems = l.split('\t')
        if len(elems)==2 and elems[0] == "real":
            minutes, entire_seconds, dec_seconds = tuple(time_reg_exp.match(elems[1]).groups())
            time_elapsed = float(minutes) * 60.0 + float(entire_seconds + "." + dec_seconds)

print("{} {} {}".format(time_elapsed, float(format(total_power * time_elapsed, '.6f')),float(format(cpu_use * time_elapsed, '.3f')) ))
