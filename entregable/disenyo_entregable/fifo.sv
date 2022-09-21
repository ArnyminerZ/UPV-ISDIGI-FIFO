//
// Proyecto de diseño de una memoria FIFO de 8 bits
// Desarrollado por: Arnau Mora Gras
// Para la práctica 1 de Integración de Sistemas Digitales de Ingeniería de
//   Telecomunicaciones de la Universitat Politècnica de València
//
// Repositorio: https://github.com/ArnyminerZ/UPV-ISDIGI-FIFO
//

module
  
fifo #(
  parameter [1:0] st_empty = 1'd0,
  parameter [1:0] st_full  = 1'd1,
  parameter [1:0] st_other = 1'd2,
  parameter [1:0] st_reset = 1'd3
)(
  // Entradas
  input CLOCK, RESET_N, READ, WRITE, CLEAR_N, // Input flags
  input [7:0] DATA_IN,              // Input data

  // Salidas
  output logic [7:0] DATA_OUT,      // Output data
  output logic F_FULL_N, F_EMPTY_N,              // Output flags
  output logic [4:0] USE_DW            // Usage flag
);

// Bus interno de almacenaje de dirección de lectura y escritura
reg [7:0] waddr, raddr; // aka countw, countr

reg [7:0] DATA_OUT_RAM, DATA_OUT_INTERNAL;

// Se usa esta flag ya que la RAM actualiza el valor de salida, en este
// caso DATA_OUT_RAM. Cuando este valor se debe escribir en la salida,
// se actualizará cp_ram a 1, para indicar que el valor de la salida
// debe ser DATA_OUT_RAM y no DATA_OUT_INTERNAL
reg cp_ram; // Indica que se debe usar el valor de la RAM

// -- ESTADOS MÁQUINA --
reg [1:0] state, nextstate;

// Declaración del módulo de memoria
ram_dp #(.mem_depth(32), .size(8))
RAM (
  .data_in(DATA_IN),      // Datos de entrada
  .wren(WRITE),           // Flag de escritura
  .rden(READ),            // Flag de lectura
  .clock(CLOCK),          // Señal de reloj
  .wraddress(waddr),      // Dirección de escritura
  .rdaddress(raddr),      // Dirección de lectura
  .data_out(DATA_OUT_RAM) // Salida de datos
);

// ! -- CONTROL PATH -- !
// El always de transiciones de estado se controla por el reloj
always @(posedge CLOCK, negedge RESET_N, negedge CLEAR_N)
begin
  if (!RESET_N || !CLEAR_N)
    state <= st_reset;
  else
    state <= nextstate;
end

always @(READ, WRITE, state, USE_DW)
begin
  case (state)
    st_empty:
    if (WRITE == 1'b1)
      if (READ == 1'b1)
        nextstate <= st_empty;
      else
        nextstate <= st_other;
    else
      nextstate <= st_empty;
    
    st_other:
    if (WRITE == 1'b1)
      if (READ == 1'b1)
        nextstate <= st_other;
      else if (USE_DW == 5'd31)
        nextstate <= st_full;
      else
        nextstate <= st_other;
    else
      // if (READ == 1'b1)
      //   if (USE_DW == 5'd1)
      //     nextstate <= st_empty;
      //   else
      //     nextstate <= st_other;
      // else
      //   nextstate <= st_other;
      if (READ == 1'b1 && USE_DW == 5'd1)
        nextstate <= st_empty;
      else
        nextstate <= st_other;
    
    st_full:
    if (WRITE == 1'b1 || READ == 1'b0)
      nextstate <= st_full;
    else
      nextstate <= st_other;

    st_reset:
      nextstate <= st_empty;
  endcase
end

// ! -- DATA PATH -- !
// State machine
always @(state)
begin
  case (state)
    st_reset:
    begin
      F_EMPTY_N <= 1'b0;         // Establecemos que la memoria está vacía
      F_FULL_N  <= 1'b1;         // Establecemos que la memoria no está llena
      cp_ram <= 1'b0;            // Reiniciamos la flag de copia de RAM
      raddr <= 8'b0;             // Reiniciamos el contador del puntero de lectura
      waddr <= 8'b0;             // Reiniciamos el contador del puntero de escritura
      USE_DW <= 5'b0;            // Reiniciamos el contador de uso
      DATA_OUT_INTERNAL <= 8'b0; // Reiniciamos la memoria de salida de datos
    end

    st_empty:
    begin
      F_EMPTY_N <= 0;
      F_FULL_N  <= 1;
      if (WRITE == 1'b1)
      begin
        if (READ == 1'b1)
        begin
          cp_ram <= 0;
          DATA_OUT_INTERNAL <= DATA_IN;
        end
        else
        begin
          waddr <= waddr+1;
          USE_DW <= USE_DW+1;
          // RAM[waddr] <= DATA_IN;
        end
      end
    end
    st_other:
    begin
      F_EMPTY_N <= 1;
      F_FULL_N  <= 1;
      case ({READ, WRITE})
      2'b11:
      begin
        raddr <= raddr + 1;
        waddr <= waddr + 1;
        // DATA_OUT <= RAM[raddr];
        cp_ram <= 1; // Block write
        // RAM[waddr] <= DATA_IN;
      end
      2'b10:
      begin
        waddr <= waddr + 1;
        USE_DW <= USE_DW+1;
        // RAM[waddr] <= DATA_IN;
      end
      2'b01:
      begin
        raddr <= raddr + 1;
        USE_DW <= USE_DW - 1;
        // DATA_OUT <= RAM[raddr];
        cp_ram <= 1; // Block write
      end
      endcase
    end
    st_full:
    begin
      F_EMPTY_N <= 1;
      F_FULL_N  <= 0;
      if (READ == 1'b1)
      begin
        if (WRITE == 1'b1)
        begin
          raddr <= raddr + 1;
          waddr <= waddr + 1;
          // DATA_OUT <= RAM[raddr];
          cp_ram <= 1; // Block write
          // RAM[waddr] <= DATA_IN;
        end
        else
        begin
          raddr <= raddr + 1;
          USE_DW <= USE_DW - 1;
          // DATA_OUT <= RAM[raddr];
          cp_ram <= 1; // Block write
        end
      end
    end
    default:
    begin
    // Should not happen
    end
  endcase
end

assign DATA_OUT = cp_ram ? DATA_OUT_RAM : DATA_OUT_INTERNAL;

endmodule
