`timescale 1 ns/ 1ps

module FIFO_ram_un_anillo (CLOCK,RESET_N, DATA_IN, READ, WRITE,CLEAR_N, F_FULL_N,F_EMPTY_N, DATA_OUT,F_LAST_N,F_FIRST_N);
    parameter DEPTH=32, WIDTH=8;
	localparam ADDRESS=$clog2(DEPTH-1);
	
  
  input   CLOCK, RESET_N, READ,WRITE,CLEAR_N;
    input   [WIDTH-1:0] DATA_IN;
    output  F_FULL_N, F_EMPTY_N, F_LAST_N,F_FIRST_N;
    output [WIDTH-1:0] DATA_OUT;


    wire  F_FULL_N, F_EMPTY_N, F_LAST_N,F_FIRST_N;
    reg [WIDTH-1:0] DATA_OUT_normal,DATA_OUT_reg;
    reg [ADDRESS-1:0]  COUNTWR,COUNTRD, COUNTRD_REG;
    reg [DEPTH:0] COUNTDEF;
	
    //(* ramstyle = "no_rw_check" *) 
	 // reg [WIDTH-1:0] PILA [DEPTH-1:0]; 
    reg [WIDTH-1:0] aux;
	reg FLAG;
 always @ (posedge CLOCK)
 begin
	 if (READ==1'b1 && WRITE==1'b1 && COUNTDEF[DEPTH]==1'b1)  
	   begin
		DATA_OUT_reg<=DATA_IN;
		FLAG<=1'b1;
		end
	 if (COUNTDEF[DEPTH]!=1'b1 && READ==1'b1)
		FLAG<=1'b0;
 end

 
RAM_DP #(.mem_depth(32),  .size(8)) PILA
(.data_in(DATA_IN),
 .wren (WRITE),
 .clock(CLOCK),
 .rden(READ),
 .data_out(DATA_OUT_normal),
 .rdaddress(COUNTRD),
 .wraddress(COUNTWR));
 

	
   always@ (posedge CLOCK or negedge RESET_N)
      if (!RESET_N)
        begin
			COUNTDEF <= {1'b1,{DEPTH{1'b0}}};
			COUNTWR  <= 5'b0;
         COUNTRD  <= 5'b0;
        end
      else
        if (!CLEAR_N)
          begin
				COUNTDEF <= {1'b1,{DEPTH{1'b0}}};
				COUNTWR  <= 5'b0;
				COUNTRD  <= 5'b0;
          end
        else
         case ({WRITE,READ})
            2'b10:
                if (F_FULL_N)
                begin
				   // PILA[COUNTWR]<= DATA_IN;
                    COUNTWR <= COUNTWR +1;
                    COUNTDEF <={COUNTDEF[0],COUNTDEF[DEPTH:1]};
                end
            2'b01:
                if (F_EMPTY_N)
                begin
						//DATA_OUT_normal<=PILA[COUNTRD];
						//DATA_OUT_normal<=aux;
                  COUNTRD <= COUNTRD +1;
                  COUNTDEF <={COUNTDEF[DEPTH-1:0],COUNTDEF[DEPTH]};
                end
            2'b11:
               begin
				//PILA[COUNTWR]<= DATA_IN;
				//DATA_OUT_normal<=PILA[COUNTRD];
					//DATA_OUT_normal<=aux;				
               COUNTWR <= COUNTWR +1;
               COUNTRD <= COUNTRD +1;
               end
         endcase //case
			
			
			
 

  // assign DATA_OUT= DATA_OUT_normal;
   assign DATA_OUT=(FLAG)? DATA_OUT_reg: DATA_OUT_normal;  //cuando esta vacio el valor válido es el old value. esto es un superdetalle
   assign F_EMPTY_N=!COUNTDEF[DEPTH];
   assign F_FULL_N=!COUNTDEF[0];
   assign F_FIRST_N=!COUNTDEF[DEPTH-1];
   assign F_LAST_N=!COUNTDEF[1];

`ifdef VERIFICACION

property  llenado ;
(@(posedge CLOCK) not (WRITE==1'b1 && F_FULL_N==1'b0 &&READ==1'b0));
endproperty
sobrellenado:assert property (llenado)  else $error("estas escribiendo sobre una fifo llena");

property  vaciado ;
(@(posedge CLOCK) not (READ==1'b1 && F_EMPTY_N==1'b0&& WRITE==1'b0)) ;
endproperty
sobrevaciado:assert property  (vaciado) else $error("estas leyendo de una fifo vacia");

puntero_llenado: assert property (@(posedge CLOCK) disable iff
(RESET_N===1'bx) $onehot(COUNTDEF)) else $error("te pille");

ejemplo_ESCRITURA1: assert property (@(posedge CLOCK) disable iff
(RESET_N===1'bx) (WRITE&&!READ&&!F_EMPTY_N)|=> !F_FIRST_N );
ejemplo_ESCRITURA2: assert property (@(posedge CLOCK) disable iff(RESET_N===1'bx) (WRITE&&!READ&&!F_LAST_N)|=> !F_FULL_N );
ejemplo_LECTURA1: assert property (@(posedge CLOCK) disable iff(RESET_N===1'bx) (!WRITE&&READ&&!F_FIRST_N)|=> !F_EMPTY_N );
ejemplo_LECTURA2: assert property (@(posedge CLOCK) disable iff(RESET_N===1'bx) (!WRITE&&READ&&!F_FULL_N)|=> !F_LAST_N );

ejemplo_CORNER_CASE_vacio: assert property (@(posedge CLOCK) 
disable iff(RESET_N===1'bx) (WRITE&&READ&&F_EMPTY_N==1'b0)|->corner_vacio);
sequence corner_vacio;
 logic [7:0] aux;
  (1, aux=DATA_IN) ##1 (!F_EMPTY_N && DATA_OUT==aux);
endsequence

ejemplo_evaluar_puntero: assert property (@(posedge CLOCK) disable iff(RESET_N===1'bx) (WRITE)|->incrementar_puntero);
sequence incrementar_puntero;
 logic [4:0] aux;
  (1, aux=COUNTWR) ##1 (COUNTWR==aux+4'b1);
endsequence


 //aserciones por verificar que son muy sofisticadas que quartus 7,1 no acepta, sin emabargo en la version 15 si que las acepta

genvar i;
   generate 
     for (i=31;i>=0;i=i-1)
       begin: width
	sequence comprobacion_fifo;
		logic [7:0] dato;
              (1, dato=DATA_IN) ##1 READ[->i+1] ##1  (DATA_OUT==dato, $display("DATA_OUT=%h y dato=%h  cuando estadoFIFO=%d ",DATA_OUT,dato,i));
	endsequence
         ejemplo_evaluar_fifo: assert property (@(posedge CLOCK) disable 		//		
	 iff(RESET_N===1'bx) (WRITE&&!READ&&(COUNTDEF[32-i]==1))|->comprobacion_fifo)
         else $error("cuidadin");  
         ejemplo_cubrir_fifo: cover property (@(posedge CLOCK) disable 		//		
	 iff(RESET_N===1'bx) (WRITE&&!READ&&(COUNTDEF[32-i]==1))|->comprobacion_fifo);  
	sequence comprobacion_fifo2;
		logic [7:0] dato;
              (1, dato=DATA_IN) ##1 READ[->i] ##1  (DATA_OUT==dato, $display("DATA_OUT=%h y dato=%h  cuando estadoFIFO=%d ",DATA_OUT,dato,i));
	endsequence
         ejemplo_evaluar_fifo2: assert property (@(posedge CLOCK) disable 		//		
	 iff(RESET_N===1'bx) (WRITE&&READ&&(COUNTDEF[32-i]==1))|->comprobacion_fifo2)
         else $error("cuidadin");  
         ejemplo_cubrir_fifo2: cover property (@(posedge CLOCK) disable 		//		
	 iff(RESET_N===1'bx) (WRITE&&READ&&(COUNTDEF[32-i]==1))|->comprobacion_fifo2); 
      	end
   endgenerate
	
	sequence comprobacion_fifo_llena;
		logic [7:0] dato;
              (1, dato=DATA_IN) ##1 READ[->32] ##1  (DATA_OUT==dato, $display("DATA_OUT=%h y dato=%h  cuando estadoFIFO=%d ",DATA_OUT,dato,32));
	endsequence
         ejemplo_evaluar_fifo_llena: assert property (@(posedge CLOCK) disable 		//		
	 iff(RESET_N===1'bx) (WRITE&&READ&&(COUNTDEF[0]==1))|->comprobacion_fifo_llena)
         else $error("cuidadin"); 
         ejemplo_cubrir_fifo_llena: cover property (@(posedge CLOCK) disable 		//		
	 iff(RESET_N===1'bx) (WRITE&&READ&&(COUNTDEF[0]==1))|->comprobacion_fifo_llena);  
		   
			
			
  covergroup punteros @(negedge CLOCK);

      r:coverpoint  COUNTRD;
      w:coverpoint  COUNTWR;
      dif:coverpoint  COUNTDEF {
      bins lleno = {2**0} ;
      bins casi_lleno={2**1};
      bins vacio = {'h100000000} ;
      bins casi_vacio={2**31};  
    }
      cross r,w;  
  endgroup; 
  
  punteros hola=new;
  
  

       `endif 
 
endmodule

