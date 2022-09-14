module 

RAM_DP #(parameter mem_depth=32, parameter size=8)
(
input [size-1:0] data_in,
input wren,clock,rden,
input [$clog2(mem_depth-1)-1:0] wraddress, 
input [$clog2(mem_depth-1)-1:0] rdaddress,
output logic [size-1:0] data_out
);

logic [size-1:0] mem [mem_depth-1 :0];

always_ff @(posedge clock)
begin
  if (wren==1'b1)
        mem[wraddress]<=data_in;
   if (rden==1'b1)
			data_out<=mem[rdaddress];   
end     


ejemplo_evaluar_ram: assert property (@(posedge clock)  (wren&&wraddress==rdaddress)##1 !wren&&$stable(rdaddress)|->NO_BYPASS);
sequence NO_BYPASS;
 logic [7:0] aux, aux2;
  (1, aux=data_in, aux2=mem[rdaddress]) ##1 (data_out===aux2) ##1 (data_out===aux) ;
endsequence


endmodule 