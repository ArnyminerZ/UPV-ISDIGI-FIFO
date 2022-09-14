class fifo_RCSG;
  rand bit[7:0] data;
  rand integer wr_cmds;
  rand integer rd_cmds;
  constraint data_acotado {data>8'h33 && data<8'hee;}
  
  function void pre_randomize();
    $display("Before randomize dato=%h", data);
  endfunction
  function void post_randomize();
    $display("After randomize dato=%h",data);
  endfunction
endclass
