`timescale 1 ns/ 1 ps
`ifndef FIFO_PORTS_SV
`define FIFO_PORTS_SV

interface fifo_if (
  input  bit        clk)  ;    
  logic       rst      ;
  logic       lleno    ;
  logic       vacio    ;
  logic       casi_lleno ;
  logic       casi_vacio;
  logic       rd_en    ; 
  logic       wr_en    ;
  logic [7:0] data_in  ;
  logic  [7:0] data_out;

clocking px @(posedge clk);
	input #1ns data_out;
	input #1ns data_in;
	input #1ns    lleno;
  input #1ns      vacio;
  input #1ns      casi_lleno;
  input #1ns      casi_vacio;
  input #1ns       rd_en; 
  input #1ns       wr_en;  
endclocking:px;
clocking tx @(posedge clk);
  input #2ns data_out;
  output #2ns data_in;
  input #2ns     lleno;
  input #2ns      vacio;
  input #2ns      casi_lleno ;
  input #2ns      casi_vacio;
  output #2ns       rd_en; 
  output #2ns       wr_en;  
endclocking:tx;



modport monitor (clocking px,

  input        rst      

);
modport test (clocking tx,

  output         rst      

);
modport duv (
  input          	clk      ,
  input        	 	rst      ,
  output         	lleno     ,
  output         	vacio    ,
  output         	casi_lleno  ,
  output 	     	casi_vacio  ,
  output         	rd_en    , 
  output 		 	wr_en    ,
  input  			data_in  ,
  output    		data_out
);



endinterface


`endif
