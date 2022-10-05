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
wire [1:0] state, nextstate; // TODO: Remove temporal outputs
wire cp_ram;
wire [4:0] countw, countr;
wire [7:0] DATA_OUT_RAM, DATA_OUT_INTERNAL;
wire [7:0] mem [31:0];
wire [7:0] DATA_IN_RAM;

fifo modulo_fifo(
    .CLOCK(CLOCK),
    .RESET_N(RESET_N),
    .READ(READ),
    .WRITE(WRITE),
    .CLEAR_N(CLEAR_N),
    .DATA_IN(DATA_IN),
    .DATA_OUT(DATA_OUT),
    .F_FULL_N(F_FULL_N),
    .F_EMPTY_N(F_EMPTY_N),
    .USE_DW(USE_DW),
    // TODO: Remove temporal outputs
    .state(state),
    .nextstate(nextstate),
    .cp_ram(cp_ram),
    .countw(countw),
    .countr(countr),
    .DATA_OUT_RAM(DATA_OUT_RAM),
    .DATA_OUT_INTERNAL(DATA_OUT_INTERNAL),
    .mem(mem),
    .DATA_IN_RAM(DATA_IN_RAM)
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
  DATA_IN <= value;                  // Escribimos el valor dado
  repeat(2) @(negedge CLOCK);        // Esperamos un ciclo de reloj
  WRITE = 1'b1;                      // Habilitamos la escritura
  repeat(1) @(negedge CLOCK);        // Esperamos un ciclo de reloj
  WRITE = 1'b0;                      // Reiniciamos la flag de escritura
end
endtask

task read;
  output bit [7:0] bits;
begin
  READ = 1'b1;                       // Habilitamos la lectura
  repeat(1) @(negedge CLOCK);        // Esperamos un ciclo de reloj
  bits = DATA_OUT;
  READ = 1'b0;                       // Reiniciamos la flag de lectura
end
endtask

// * Genera un número aleatorio entre 0 y max
function int aleatorio(int max);
  return {$random} % max;
endfunction

// ! -- TAREAS -- !
task reset;
begin
  CLOCK = 0;
  READ = 0;
  WRITE = 0;
  RESET_N = 1;
  CLEAR_N = 1;
  DATA_IN = 0;

  $display("Reiniciando modulo...");
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
  bit [7:0] value;             // Declaramos la variable que guardará el valor a escribir
  bit [4:0] used;              // Declaramos la variable que guarda el valor de USE_DW al principio de la tarea
  repeat(10) @(negedge CLOCK); // Separamos la tarea 10 ciclos

  used = USE_DW;               // Guardamos el valor de USE_DW
  // value = aleatorio(2^8);   // Generamos un número aleatorio de 8 bits
  value = 8'd37;               // TODO: Se debería usar la función aleatorio, pero no funciona
  $display("Se va a escribir el valor", value);

  write(value);                   // Escribimos el valor 11 en la memoria

  if (USE_DW == (used + 1))          // Comprobamos que el contador de uso se ha incrementado
    $display("ESCRITURA: OK (USE_DW+)");
  else
    $error("ESCRITURA: FAIL - El contador de uso deberia estar a", used + 1, ". USE_DW =", USE_DW);

  read(bits);                  // Leemos el valor de la memoria
  repeat(5) @(negedge CLOCK);        // Esperamos 5 ciclos de reloj

  if (bits == value)           // Comprobamos que el valor leído es el correcto
    $display("ESCRITURA: OK (READ)");
  else
    $error("ESCRITURA: FAIL - El valor leido no es igual al escrito. bits =", bits);
    
  if (USE_DW == used)          // Comprobamos que el contador de uso se ha reducido
    $display("ESCRITURA: OK (USE_DW-)");
  else
    $error("ESCRITURA: FAIL - El contador de uso deberia estar a", used, ". USE_DW =", USE_DW);

  // Como hemos escrito y leído, la memoria debería estar vacía
  if (F_EMPTY_N == 1'b1)
    $error("ESCRITURA: FAIL - La FIFO deberia estar vacia. F_EMPTY_N =", F_EMPTY_N);
  else
    $display("ESCRITURA: OK (EMPTY)");
  if (F_FULL_N == 1'b0)
    $error("ESCRITURA: FAIL - La FIFO no deberia estar llena. F_FULL_N =", F_FULL_N);
  else
    $display("ESCRITURA: OK (FULL)");
end
endtask

// Comprobamos qué pasa cuando se llena la memoria
// Esta tarea también comprueba que los contadores se modifican adecuadamente
task overflow;
begin
  $display("Llenando memoria...");
  // Escribimos sólo 31 valores ya que ya hemos usado el primer slot de memoria
  repeat(31) begin // Llenamos la memoria con 11s
    write(8'd11);
  end
  // Ahora la memoria ya debería estar llena

  if (USE_DW == 31)           // Comprobamos que el contador de uso se ha reducido
    $display("OVERFLOW: OK (USE_DW-)");
  else
    $error("OVERFLOW: FAIL - El contador de uso deberia estar a 31. USE_DW =", USE_DW);

  // La memoria debería estar llena
  if (F_EMPTY_N == 1'b0)
    $error("OVERFLOW: FAIL - La FIFO no deberia estar vacia. F_EMPTY_N =", F_EMPTY_N);
  else
    $display("OVERFLOW: OK (not EMPTY)");
  if (F_FULL_N == 1'b1)
    $error("OVERFLOW: FAIL - La FIFO deberia estar llena. F_FULL_N =", F_FULL_N);
  else
    $display("OVERFLOW: OK (FULL)");
end
endtask

initial begin
  $display("Estableciendo valores por defecto...");
  reset();
  $display("Simulando...");
  empty_check();
  escritura();
  overflow();
end

// * Genera la señal de reloj con un periodo igual al parámetro T
always
begin
  #(T/2) CLOCK <= ~CLOCK;
end
`endif

endmodule
