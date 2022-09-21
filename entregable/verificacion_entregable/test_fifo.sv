// Establecemos la escala de tiempo
`timescale 1 ns / 1 ns

`define VERIFICAR;

localparam T=20;

module test_fifo();

// Entradas
reg CLOCK, RESET_N, READ, WRITE, CLEAR_N;
reg [7:0] DATA_IN;

// Salidas
wire [7:0] DATA_OUT;
wire F_FULL_N, F_EMPTY_N;
wire [4:0] USE_DW;

fifo modulo_fifo(
    .CLOCK(CLOCK),
    .RESET_N(RESET_N),
    .READ(READ),
    .WRITE(WRITE),
    .CLEAR_N(CLEAR_N),
    .DATA_OUT(DATA_OUT),
    .F_FULL_N(F_FULL_N),
    .F_EMPTY_N(F_EMPTY_N),
    .USE_DW(USE_DW)
);

`ifdef VERIFICAR
// ! VERIFICACIÓN !
// Notas:
//   #<delay>           - Espera x tiempo
//   @(<signal>)        - Espera a que <signal> cambie (posedge/negedge)
//   Wait(<expression>) - Espera a que <expression> sea verdadero
// * Nota: No usar tildes en los mensajes ya que ModelSim no los muestra correctamente

// ! -- FUNCIONES -- !
task write;
  input bit [7:0] value;             // Declaramos la entrada para el valor a escribir
begin
  WRITE = 1'b1;                      // Habilitamos la escritura
  DATA_IN <= value;                  // Escribimos el valor dado
  repeat(1) @(negedge CLOCK);        // Esperamos un ciclo de reloj
  WRITE = 1'b0;                      // Reiniciamos la flag de escritura
end
endtask

task read;
  output bit [7:0] bits;
begin
  READ = 1'b1;                       // Habilitamos la lectura
  bits = DATA_OUT;
  repeat(1) @(negedge CLOCK);        // Esperamos un ciclo de reloj
  READ = 1'b0;                       // Reiniciamos la flag de lectura
end
endtask

// ! -- TAREAS -- !
task reset;
begin
  CLOCK = 0;
  READ = 0;
  WRITE = 0;
  RESET_N = 1;
  DATA_IN = 0;

  $display("Reiniciando módulo...");
  repeat(1) @(negedge CLOCK);        // Esperamos un ciclo de reloj
  RESET_N = 0;                       // Reiniciamos
  repeat(1) @(negedge CLOCK);        // Esperamos otro ciclo
  RESET_N = 1;                       // Desconectamos la señal de reinicio
end
endtask

// * Comprueba que la memoria está vacía
task empty_check;
begin
  repeat(10) @(negedge CLOCK); // Separamos la tarea 10 ciclos

  READ = 1'b1;
  WRITE = 1'b0;
  repeat(2) @(negedge CLOCK);

  if (F_EMPTY_N == 1'b1)
    $error("VACIO: FAIL - La FIFO deberia estar vacia. F_EMPTY_N =", F_EMPTY_N);
  else
    $display("VACIO: OK (EMPTY)");
  if (F_FULL_N == 1'b0)
    $error("VACIO: FAIL - La FIFO no deberia estar llena. F_FULL_N =", F_FULL_N);
  else
    $display("VACIO: OK (FULL)");
  if (USE_DW == 5'b0)
    $display("VACIO: OK (USE_DW)");
  else
    $error("VACIO: FAIL - El contador de uso deberia estar a 0. USE_DW =", USE_DW);

  READ = 1'b0;
end
endtask

// * Escribe un valor en la memoria. Asume que la memoria está vacía en un principio
task escritura;
begin
  bit [7:0] bits;              // Declaramos la variable bits para guardar el valor de lectura
  repeat(10) @(negedge CLOCK); // Separamos la tarea 10 ciclos

  write(11);                   // Escribimos el valor 11 en la memoria
  if (USE_DW == 5'd1)          // Comprobamos que el contador de uso se ha incrementado
    $display("ESCRITURA: OK (USE_DW)");
  else
    $error("ESCRITURA: FAIL - El contador de uso deberia estar a 1. USE_DW =", USE_DW);

  read(bits);                  // Leemos el valor de la memoria
  if (bits == 8'd11)           // Comprobamos que el valor leído es el correcto
    $display("ESCRITURA: OK (READ)");
  else
    $error("ESCRITURA: FAIL - El valor leido no es igual al escrito. bits =", bits);
end
endtask

initial begin
  $display("Estableciendo valores por defecto...");
  reset();
  $display("Simulando...");
  empty_check();
  escritura();
end

always
begin
  #(T/2) CLOCK <= ~CLOCK;
end
`endif

endmodule
