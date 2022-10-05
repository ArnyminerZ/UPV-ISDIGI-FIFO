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
  parameter [1:0] st_empty = 2'd0,
  parameter [1:0] st_full  = 2'd1,
  parameter [1:0] st_other = 2'd2,
  parameter [1:0] st_reset = 2'd3
)(
  // Entradas
  input CLOCK, RESET_N, READ, WRITE, CLEAR_N, // Input flags
  input [7:0] DATA_IN,                        // Input data

  // Salidas
  output logic [7:0] DATA_OUT,                // Output data
  output logic F_FULL_N, F_EMPTY_N,           // Output flags
  output logic [4:0] USE_DW,                  // Usage flag

  // TODO: Remove temporal output
  output logic [1:0] state, nextstate,
  output logic [4:0] countw, countr,
  output logic cp_ram,
  output logic [7:0] DATA_OUT_RAM, DATA_OUT_INTERNAL,
  output logic [7:0] mem [31:0],
  output logic [7:0] DATA_IN_RAM
);

// Bus interno de almacenaje de dirección de lectura y escritura
// reg [7:0] addr, addr; // aka countw, countr

// logic [7:0] DATA_OUT_RAM, DATA_OUT_INTERNAL;
// logic [7:0] DATA_IN_RAM;

// Se usa esta flag ya que la RAM actualiza el valor de salida, en este
// caso DATA_OUT_RAM. Cuando este valor se debe escribir en la salida,
// se actualizará cp_ram a 1, para indicar que el valor de la salida
// debe ser DATA_OUT_RAM y no DATA_OUT_INTERNAL
// TODO: Remove temporal output
// reg cp_ram; // Indica que se debe usar el valor de la RAM

// -- ESTADOS MÁQUINA --
// output reg [1:0] state, nextstate; // TODO: Remove temporal output

// Declaración del módulo de memoria
ram_dp RAM (
  .data_in(DATA_IN_RAM),   // Datos de entrada
  .wren(WRITE),           // Flag de escritura
  .rden(READ),             // Flag de lectura
  .clock(CLOCK),           // Señal de reloj
  .wraddress(countw),        // Dirección de escritura
  .rdaddress(countr),        // Dirección de lectura
  .data_out(DATA_OUT_RAM), // Salida de datos
  .mem(mem)
);

// ! --  ----------  -- !
// ! -- CONTROL PATH -- !
// ! --  ----------  -- !
// El always de transiciones de estado se controla por el reloj
always @(negedge CLOCK, negedge RESET_N, negedge CLEAR_N)
begin
  if (!RESET_N || !CLEAR_N)               // * Si se activan las entradas de clear o reset
    state <= st_reset;                    // Pon la maquina de estados en reset
  else                                    // * De lo contrario
    state <= nextstate;                   // Copia "el siguiente estado" al actual
end

always @(READ, WRITE, state, USE_DW)
begin
  case (state)
    st_empty:                             // * La máquina de estados está en "vacío"
    if (WRITE == 1'b1)                    // * Si se va a escribir
      if (READ == 1'b1)                   // * Y también leer
        nextstate <= st_empty;            // La máquina va a seguir estando vacía
      else                                // * Si sólo se quiere escribir
        nextstate <= st_other;            // La máquina no va a estar ni llena ni vacía
    else                                  // * Si no se va a realizar ninguna acción
      nextstate <= st_empty;              // La máquina va a seguir estando vacía
    
    st_other:                             // * Si la máquina no está ni llena ni vacía
    if (WRITE == 1'b1)                    // * Se quiere escribir
      if (READ == 1'b1)                   // * Y también leer
        nextstate <= st_other;            // La máquina va a seguir estando ni llena ni vacía
      else if (USE_DW == 5'd31)           // * Si no se quiere leer, y la memoria se ha llenado
        nextstate <= st_full;             // La máquina va a estar llena
      else                                // * Si sólo se quiere escribir, y la memoria no se ha llenado aún
        nextstate <= st_other;            // La máquina va a seguir estando ni llena ni vacía
    else
      if (READ == 1'b1 && USE_DW == 5'd1) // * Si no se quiere escribir, pero sí leer, y la memoria sólo tiene un elemento
        nextstate <= st_empty;            // La máquina va a estar vacía
      else                                // * Si no se quiere leer ni escribir
        nextstate <= st_other;            // La máquina va a seguir estando ni llena ni vacía
    
    st_full:                              // * Si la máquina está llena
    if (READ == 1'b1 && WRITE == 1'b0)    // * Si se quiere leer pero no escribir
      nextstate <= st_other;              // La máquina no va a estar ni llena ni vacía
    else                                  // * Si no se va a leer
      nextstate <= st_full;               // La máquina va a seguir estando llena

    st_reset:                             // * Si se ha reiniciado el sistema
      nextstate <= st_empty;              // La máquina va a estar vacía
  endcase
end

// ! --  -------  -- !
// ! -- DATA PATH -- !
// ! --  -------  -- !
// State machine
always @(state, READ, WRITE, cp_ram)
begin
  case (state)
    st_reset:
    begin
      F_EMPTY_N <= 1'b0;                  // Establecemos que la memoria está vacía
      F_FULL_N  <= 1'b1;                  // Establecemos que la memoria no está llena
      cp_ram <= 1'b0;                     // Reiniciamos la flag de copia de RAM
      countr <= 5'b0;                     // Reiniciamos el contador del puntero de lectura
      countw <= 5'b0;                     // Reiniciamos el contador del puntero de escritura
      USE_DW <= 5'b0;                     // Reiniciamos el contador de uso
      DATA_OUT_INTERNAL <= 8'b0;          // Reiniciamos la memoria de salida de datos
    end

    st_empty:
    begin
      F_EMPTY_N <= 0;                     // Está vacío
      F_FULL_N  <= 1;                     // No está lleno
      if (WRITE == 1'b1)                  // * Sólo realizar acciones si se va a escribir
      begin
        // $display("> Writing on empty memory.");
        if (READ == 1'b1)                 // * Si también se lee
        begin
          // $display("> Moving value from input to output");
          DATA_OUT_INTERNAL <= DATA_IN;   // Copia los datos desde la entrada a la salida
        end
        else                              // * Si sólo se quiere escribir
        begin
          countw <= countw + 1;           // Mueve el puntero de dirección a la derecha
          USE_DW <= USE_DW + 1;           // Aumenta el uso de memoria
          DATA_IN_RAM <= DATA_IN;         // Copia los datos desde la RAM a la salida
          // $display("> Writing value to RAM. countw:", countw, ". Value:", DATA_IN);
        end
      end
    end

    st_other:
    begin
      F_EMPTY_N <= 1;                     // No está vacío
      F_FULL_N  <= 1;                     // No está lleno
      case ({WRITE, READ})
      2'b11:                              // * Si se va a leer y a escribir
      begin
        DATA_IN_RAM <= DATA_IN;           // Copia los datos de entrada a la RAM
        // $display("> Copying data from input to output. Value:", DATA_IN);
      end
      2'b10:                              // * Si sólo se va a escribir
      begin
        countw <= countw + 1;             // Mueve el puntero de dirección a la derecha
        USE_DW <= USE_DW + 1;             // Incrementa el uso de memoria
        DATA_IN_RAM <= DATA_IN;           // Copia los datos de entrada a la RAM
        // $display("> Writing data to RAM. countw:", countw, ". Value:", DATA_IN);
      end
      2'b01:                              // * Si sólo se va a leer
      begin
        countr <= countr + 1;             // Mueve el puntero de dirección a la izquierda
        cp_ram = 1;                       // Assigna la salida desde la RAM
        // $display("> Reading from RAM. countr:", countr, ". Value:", DATA_IN_RAM);
      end
      default:
      begin
        // No realizar ninguna acción
      end
      endcase
    end

    st_full:
    begin
      F_EMPTY_N <= 1;                     // No está vacío
      F_FULL_N  <= 0;                     // Está lleno
      if (READ == 1'b1)                   // * Sólo realizar acciones si se va a leer
      begin
        if (WRITE == 1'b1)                // * Si también se quiere escribir
        begin
          DATA_IN_RAM <= DATA_IN;         // Copia los datos de entrada a la RAM
          // $display("> Copying data from input to output. Value:", DATA_IN_RAM);
        end
        else                              // * Si sólo se quiere leer
        begin
          countr <= countr + 1;           // Mueve el puntero de dirección a la izquierda
          cp_ram = 1;                     // Asigna la salida desde la RAM
          // $display("> Reading from RAM. countr:", countr, ". Value:", DATA_IN_RAM);
        end
      end
    end
    default:
    begin
    // Should not happen, hereby unhandled states from the state machine
    end
  endcase
end

assign DATA_OUT = cp_ram ? DATA_OUT_RAM : DATA_OUT_INTERNAL;

endmodule
