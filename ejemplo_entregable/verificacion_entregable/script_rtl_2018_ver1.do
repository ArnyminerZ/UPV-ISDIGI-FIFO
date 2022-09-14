vlog -work work -vopt -sv +define+VERIFICACION -cover sbcet3 {../disenyo_entregable/RAM_DP.sv}
vlog -work work -vopt -sv +define+VERIFICACION -cover sbcet3 {../disenyo_entregable/FIFO32x2_2018_mejor_jer.sv}
vlog -reportprogress 300 -work work {fifo_ports_2013_ver1.sv}
vlog -work work -vopt -sv +define+VERIFICACION -cover sbcet3 {fifo_top_duv_2013_ver1.sv}
vlog -reportprogress 300 -work work {fifo_top_test_2014_ver2.sv}
vlog -reportprogress 300 -work work {fifo_tb_2013_ver1.sv}
vsim -L cycloneive_ver -coverage  -novopt -msgmode both  work.fifo_tb -voptargs=+acc -classdebug -uvmcontrol=all -solvefaildebug -assertcover
add wave \
sim:/fifo_tb/fifo_interfaz/wr_en \
sim:/fifo_tb/fifo_interfaz/vacio \
sim:/fifo_tb/fifo_interfaz/rst \
sim:/fifo_tb/fifo_interfaz/rd_en \
sim:/fifo_tb/fifo_interfaz/lleno \
sim:/fifo_tb/fifo_interfaz/data_out \
sim:/fifo_tb/fifo_interfaz/data_in \
sim:/fifo_tb/fifo_interfaz/clk \
sim:/fifo_tb/fifo_interfaz/casi_vacio \
sim:/fifo_tb/fifo_interfaz/casi_lleno
run -all
