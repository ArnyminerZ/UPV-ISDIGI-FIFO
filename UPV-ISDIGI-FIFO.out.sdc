## Generated SDC file "UPV-ISDIGI-FIFO.out.sdc"

## Copyright (C) 2017  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 17.1.0 Build 590 10/25/2017 SJ Lite Edition"

## DATE    "Thu Sep 22 11:09:28 2022"

##
## DEVICE  "EP4CE115F29C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK} -period 10.000 -waveform { 0.000 0.500 } [get_ports { CLOCK }]
create_clock -name {READ} -period 1.000 -waveform { 0.000 0.500 } [get_ports {READ}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {CLOCK}] -rise_to [get_clocks {CLOCK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLOCK}] -fall_to [get_clocks {CLOCK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLOCK}] -rise_to [get_clocks {READ}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {CLOCK}] -fall_to [get_clocks {READ}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {CLOCK}] -rise_to [get_clocks {CLOCK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLOCK}] -fall_to [get_clocks {CLOCK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLOCK}] -rise_to [get_clocks {READ}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {CLOCK}] -fall_to [get_clocks {READ}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {READ}] -rise_to [get_clocks {CLOCK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {READ}] -fall_to [get_clocks {CLOCK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {READ}] -rise_to [get_clocks {READ}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {READ}] -fall_to [get_clocks {READ}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {READ}] -rise_to [get_clocks {CLOCK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {READ}] -fall_to [get_clocks {CLOCK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {READ}] -rise_to [get_clocks {READ}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {READ}] -fall_to [get_clocks {READ}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

