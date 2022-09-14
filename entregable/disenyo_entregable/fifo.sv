module fifo

#(
  parameter mem_depth = 32, // Tamaño de memoria
  parameter mem_width = 8,  // Ancho de memoria
) (
  // Entradas
  input CLOCK, RESET_N, READ, WRITE, CLEAR_N, // Input flags
  input [mem_width-1:0] DATA_IN,              // Input data

  // Salidas
  output logic [mem_width-1:0] DATA_OUT,      // Output data
  output reg F_FULL_N, F_EMPTY_N, USE_DW      // Output flags
);

// Bus interno de almacenaje de dirección de lectura y escritura
reg [mem_width-1:0] waddr, raddr; // aka countw, countr

// -- FLAGS DE CONTROL --
wire cp_in;  // Indica que se deben copiar los datos del bus de entrada al de salida
wire cp_ram; // Indica que se deben copiar los datos de la RAM al bus de salida
wire wr_ram; // Indica que se debe escribir en la RAM los datos del bus de entrada

// Declaración del módulo de memoria
ram_dp #(.mem_depth(mem_depth), .size(mem_width))
RAM (
  .data_in(DATA_IN),  // Datos de entrada
  .wren(WRITE),       // Flag de escritura
  .rden(READ),        // Flag de lectura
  .clock(CLOCK),      // Señal de reloj
  .waddress(waddr),   // Dirección de escritura
  .raddress(raddr),   // Dirección de lectura
  .data_out(DATA_OUT) // Salida de datos
);

always_ff @(posedge CLOCK or negedge RESET_N)
begin
  case ({READ, WRITE})
  2'b11: // Read and Write
  begin
    if (F_FULL_N && !F_EMPTY_N) // Si está vacía (y no está llena)
	    cp_in = 1'b1;             // - Copia los datos del bus de entrada al de salida
    else if (F_EMPTY_N)
    begin                       // Si no está vacía
      cp_ram = 1'b1;            // - Copia los datos de la RAM al bus de salida
      wr_ram = 1'b1;            // - copia los datos del bus de entrada a la RAM
    end
  end
  2'b10: // Read
  begin
    if (F_EMPTY_N)              // Si no está vacía
      cp_ram = 1'b1;            // - Copia los datos de la RAM al bus de salida
  end
  2'b01: // Write
  begin
    if (F_FULL_N && !F_EMPTY_N) // Si está vacía (y no está llena)
      wr_ram = 1'b1;            // - Copia los datos del bus de entrada a la RAM
  end
  endcase


  // -- ACTUALIZAR FLAGS --
  // Si se llega al límite de uso de memoria, marcar la flag de lleno
  if (USE_DW == mem_depth-1)
    F_FULL_N = 1'b0;
  else
    F_FULL_N = 1'b1;
  // Si el uso de memoria está a 0, la flag de vacío debe estar activa
  if (USE_DW == 0)
    F_EMPTY_N = 1'b0;
  else
    F_EMPTY_N = 1'b1;

		
  // -- REINICIAR MEMORIA --
  if (RESET_N == 1'b0)
  begin
    F_FULL_N <= 1;
    F_EMPTY_N <= 0;
	 USE_DW <= 0;
	 waddr <= 0; // TODO: Usar tamaño del buffer
	 raddr <= 0; //  /\  /\  /\  /\  /\  /\  /\
  end
  
  
  // -- CONTROL --
  if (cp_in)
  begin
    DATA_OUT <= DATA_IN;
  end
  if (cp_ram)
  begin
    raddr <= raddr+1;
    DATA_OUT <= RAM[raddr];
    if (!wp_ram) // Sólo actualizar el uso cuando únicamente se ha leído de la RAM
      USE_DW <= USE_DW-1;
  end
  if (wr_ram)
  begin
	  waddr <= waddr+1;
    RAM[waddr] <= DATA_IN;
    if (!cp_ram) // Sólo actualizar el uso cuando únicamente se ha escrito en la RAM
      USE_DW <= USE_DW+1;
  end
end

endmodule
