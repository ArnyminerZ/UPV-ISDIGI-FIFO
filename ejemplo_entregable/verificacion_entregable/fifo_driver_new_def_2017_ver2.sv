class fifo_driver;
  fifo_sb sb;
  fifo_RCSG rdatos;
  virtual fifo_if.test ports;
  virtual fifo_if.monitor mports;

  bit rdDone;
  bit wrDone;

  integer wr_cmds;
  integer rd_cmds;
  covergroup COV_entradas;
      coverpoint mports.px.data_in;
      ae:coverpoint {mports.px.lleno,mports.px.wr_en,mports.px.rd_en}
      {
            bins f1w1r0={3'b110};
            bins f1w1r1={3'b111}; 
            bins f0w1r1={3'b011};
      
      }
  endgroup;
   covergroup COV_salidas;

      coverpoint  mports.px.data_out;
      as:coverpoint {mports.px.vacio,mports.px.wr_en,mports.px.rd_en}
      {
            bins e1w0r1={3'b101};
            bins e1w1r1={3'b111}; 
            bins e0w1r1={3'b011}; 
          }
  endgroup; 
// covergroup prueba_interno @(negedge mports.px);
//      interno_r:coverpoint fifo_tb.duv.fifo_duv.COUNTRD;
//      interno_w:coverpoint  fifo_tb.duv.fifo_duv.COUNTWR;
//      interno_dif:coverpoint  fifo_tb.duv.fifo_duv.COUNTDEF {
//      bins lleno = {2**0} ;
//      bins casi_lleno={2**1};
//      bins vacio = {'h100000000} ;
//      bins casi_vacio={2**31};  
//    }
//      cross interno_r,interno_w;  
//  endgroup;
  covergroup prueba_puntero @(negedge mports.px);
      rw:coverpoint {mports.px.wr_en,mports.px.rd_en}
	{  	bins simultaneo_rw = {2'b11} ;
                bins otros=default;}
      interno_dif:coverpoint  fifo_tb.test.driver.sb.size 
	{	bins lleno = {32} ;
      		bins casi_lleno={31};
      		bins vacio = {0} ;
      		bins casi_vacio={1};  
      		bins otros[]={[2:30]};}
      cross rw,interno_dif
  	{  	bins         cross1 = binsof(rw.simultaneo_rw)&&binsof(interno_dif.lleno);  
		bins         cross2 = binsof(rw.simultaneo_rw)&&binsof(interno_dif.vacio);              
    	}
  endgroup; 
    function new (virtual fifo_if.test ports, virtual fifo_if.monitor mports);
  begin
    this.ports = ports;
    this.mports = mports;
    sb = new(mports);
    rdatos=new;
      
    COV_entradas=new;
    COV_salidas=new;
    prueba_puntero=new;
    wr_cmds = 4;
    rd_cmds  = 4;
    rdDone = 0;
    wrDone = 0;
     ports.tx.wr_en  <= 0;
     ports.tx.rd_en  <= 0;
     ports.tx.data_in <= 0;
  end
  endfunction
  
  task monitorPush();
  begin
    bit [7:0] data = 0;
    while (1) begin
      @ (mports.px);
      if ( mports.px.wr_en== 1  && mports.px.lleno!= 0 ||   mports.px.wr_en== 1  && mports.px.lleno== 0 && mports.px.rd_en==1) begin
        data = mports.px.data_in;
        COV_entradas.sample(); //anyadido para cobertura
        sb.addItem(data);
        $write("%dns : Write posting to scoreboard data = %x\n",$time, data);
      end
    end
  end
  endtask

 
  task monitorPop();
  begin
    bit [7:0] data = 0;
	  @ (mports.px); 
    while (1) begin
      //@ (mports.px); //eliminado porque es lectura síncrona
      if (  mports.px.rd_en== 1 && mports.px.vacio!=0 ||  mports.px.rd_en== 1 && mports.px.vacio==0 && mports.px.wr_en==1) begin
        COV_salidas.sample(); 
        @ (mports.px) ;
        data = mports.px.data_out;//añadido porque es lectura síncrona
//anyadido para cobertura
        $write("%dns : Read posting to scoreboard data = %x\n",$time, data);
        sb.compareItem(data);
		  
      end
		else
			  @ (mports.px); 
    end
  end
  endtask
  task go1();
  begin
    // Assert reset first
    reset();
    // Start the monitors
    repeat (5) @ (ports.tx);
    $write("%dns : Starting Pop and Push monitors\n",$time);
    fork
      monitorPush();
      monitorPop();
    join_none
    $write("%dns : Starting Pop and Push generators\n",$time);
    fork
      genPush();
      @ (ports.tx)genPop(); 
    join_none

    while (!rdDone && !wrDone) begin
      @ (ports.tx);
    end
     repeat (10) @ (ports.tx);
    $write("%dns : Terminamos test1\n",$time);
  end
  endtask
  
  task go2();
  begin
    // Assert reset first
    reset();
    // Start the monitors
    repeat (5) @ (ports.tx);
     $write("%dns : Starting Pop and Push generators\n",$time);
     begin 
	   genPush();	   
	   genPush();
	   genPush();
	   genPop();
     end

    while (!rdDone) begin
      @ (ports.tx);
    end
    repeat (10) @ (ports.tx);
    $write("%dns : Terminando test2\n",$time);
  end
  endtask

task llenado();
  begin
    // Assert reset first
    reset();
    // Start the monitors
    repeat (5) @ (ports.tx);
     $write("%dns : Starting Pop and Push generators\n",$time);
     fork 
	   repeat(8) genPush();	   
     join_none

    while (ports.tx.lleno) begin
      @ (ports.tx);
    end
    repeat (10) @ (ports.tx);
    $write("%dns : Terminando test de llenado\n",$time);
  end
  endtask
task llenado_mantenido_vaciado();
  begin
    // Assert reset first
    reset();
    // Start the monitors
    repeat (5) @ (ports.tx);
     $write("%dns : Starting Pop and Push generators\n",$time);
     fork 
	   repeat(8) genPush();	   
     join_none

    while (ports.tx.lleno) begin
      @ (ports.tx);
    end
    repeat(11)   @ (ports.tx);
   
	 repeat(8) genPop();	   

    repeat(10)   @ (ports.tx);
     fork 
	   repeat(8) genPush();	   
     join_none
    while (sb.size<32) begin
      @ (ports.tx);
    end
    fork    
	 repeat(8) genPop();	   
    join_none
    while (sb.size>0) begin
      @ (ports.tx);
    end    
    repeat (10) @ (ports.tx);
    $write("%dns : Terminando test de llenado_mantenido_vaciado\n",$time);
  end
  endtask

task llenado_vaciado_random ();
begin
  wr_cmds=1;
  rd_cmds=1;  
    while ( COV_entradas.get_coverage()<90 || COV_salidas.get_coverage()<90)    
  begin
       while ( sb.size<32) //empiezo a llenar
      fork begin
          fork:pepito
           randcase
            5: genPop_rand();
            10: genPush_rand();
            endcase
           randcase
            6: genPop_rand();
            10: genPush_rand();
            endcase
           join_any: pepito
  
            $display("la fifo tiene  %d palabras", sb.size);
            $display("Instance coverage is %e", COV_entradas.get_coverage());
                     disable fork;
       end join
  
    fork //corner case
  
      genPop_atom();
      genPush_atom();
  
    join_any
       $display("la fifo tiene  %d palabras", sb.size);
      $display("Instance coverage is %e", COV_entradas.get_coverage());
     
     // driver.go2();
     // driver.llenado();
     while (sb.size>0) //empiezo a vaciar
      fork begin
      fork
         randcase
          10: genPop_rand();
          5: genPush_rand();
          endcase
         randcase
          10: genPop_rand();
          6: genPush_rand();
          endcase
      join_any
          $display("la fifo tiene  %d palabras", driver.sb.size);
      $display("Instance coverage is %e", driver.COV_entradas.get_coverage());
      disable fork;
    end join
      fork //corner case
      genPop_atom();
      genPush_atom();
       join_any
   end
 end
 endtask 
 
  task reset();
  begin
    repeat (5) @ (ports.tx);
    $write("%dns : Asserting reset\n",$time);
    ports.rst= 1'b0;
    // Init all variables
    sb.size=0; //inicializamos el puntero del mailbox que indica el llenado
    rdDone = 0;
    wrDone = 0;
    sb.vaciar();
    repeat (5) @ (ports.tx);
    ports.rst= 1'b1;
    $write("%dns : Done asserting reset\n",$time);
  end
  endtask

  task genPush();
  begin
    bit [7:0] data = 0;
    integer i = 0;
    for ( i  = 0; i < wr_cmds; i++)  begin
       data = $random();
             @ (ports.tx);
        while (ports.tx.lleno== 1'b0 & mports.px.rd_en==1'b0)
       begin

        ports.tx.wr_en <= 1'b0;
        ports.tx.data_in<= 8'b0;
              @ (ports.tx);
       end

       ports.tx.wr_en  <= 1'b1;
       ports.tx.data_in<= data;
    end
    @ (ports.tx);
    ports.tx.wr_en  <= 1'b0;
    ports.tx.data_in<= 8'b0;
    repeat (10) @ (ports.tx);
    wrDone = 1;
  end
  endtask
  task genPush_atom();
  begin
    bit [7:0] data = 0;
    integer i = 0;
    for ( i  = 0; i < wr_cmds; i++)  begin
       data = $random();
             @ (ports.tx);

       ports.tx.wr_en  <= 1'b1;
       ports.tx.data_in<= data;
    end
    @ (ports.tx);
    ports.tx.wr_en  <= 1'b0;
    ports.tx.data_in<= 8'b0;
    repeat (10) @ (ports.tx);
    wrDone = 1;
  end
  endtask 
  
    task genPush_sin();
  begin
    bit [7:0] data = 0;
    integer i = 0;
    
       data = $random();
      @ (ports.tx);
       ports.tx.wr_en  <= 1'b1;
	   $stop;
       ports.tx.data_in<= data;

    repeat (4) @ (ports.tx);
    repeat (4) @ (ports.tx);

    ports.tx.wr_en  <= 1'b0;
    ports.tx.data_in<= 8'b0;
    repeat (10) @ (ports.tx);
    wrDone = 1;
	$display("lo hice");
  end
  
  endtask
    task genPop();
  begin
    integer i = 0;
    for ( i  = 0; i < rd_cmds; i++)  begin
       @ (ports.tx);
       while (ports.tx.vacio== 1'b0 & mports.px.wr_en==1'b0) begin

         ports.tx.rd_en  <= 1'b0;
         @ (ports.tx); 
       end

       ports.tx.rd_en  <= 1'b1;
    end
    @ (ports.tx);

    ports.tx.rd_en   <= 1'b0;
    repeat (10) @ (ports.tx);
    rdDone = 1;
  end
  endtask
  task genPop_atom();
  begin
    integer i = 0;
    for ( i  = 0; i < rd_cmds; i++)  begin
       @ (ports.tx);
       ports.tx.rd_en  <= 1'b1;
    end
    @ (ports.tx);

    ports.tx.rd_en   <= 1'b0;
    repeat (10) @ (ports.tx);
    rdDone = 1;
  end
  endtask
  
  task genPop_rand();
  begin:pop
    integer i = 0;
    for ( i  = 0; i < rd_cmds; i++)  begin
       @ (ports.tx);
       while (ports.tx.vacio== 1'b0 & mports.px.wr_en==1'b0) begin

         ports.tx.rd_en  <= 1'b0;
         @ (ports.tx);
         disable pop; 
       end

       ports.tx.rd_en  <= 1'b1;
    end
    @ (ports.tx);

    ports.tx.rd_en   <= 1'b0;
    repeat (10) @ (ports.tx);
    rdDone = 1;
  end
  endtask
    task genPush_rand();
  begin:pus
  //  bit [7:0] data = 0;
    integer i = 0;
    for ( i  = 0; i < wr_cmds; i++)  begin
   //    data = $random();
       rdatos.randomize() ; //with {wr_cmds=4 && rd_cmds=4;};  
      @ (ports.tx);
       while (ports.tx.lleno== 1'b0 & mports.px.rd_en==1'b0) begin

        ports.tx.wr_en  <= 1'b0;
        ports.tx.data_in<= 8'b0;
        @ (ports.tx); 
        disable pus;
       end

       ports.tx.wr_en  <= 1'b1;
       ports.tx.data_in<= rdatos.data;
    end
    @ (ports.tx);

    ports.tx.wr_en  <= 1'b0;
    ports.tx.data_in<= 8'b0;
    repeat (10) @ (ports.tx);
    wrDone = 1;
  end
  endtask
  
  
  
endclass
