module shifter_2d


// este es un elemento del data-ptah
#(parameter tamanyo=32, parameter size=8)
(
input clock, //se�al de reloj
input reset, //reset asincrono
input enable,
input modo, //salida serie fija o variable
input [$clog2(tamanyo-1)-1:0] seleccion, 
input [size-1:0]entrada_serie,
input clear,
output logic [size-1:0] salida_serie) ;

logic [0:tamanyo-1][size-1:0] aux;


always_ff @(posedge clock  , negedge reset)       
if (!reset)
        aux<={tamanyo{'0}};
else
    if (!clear)
        aux<={tamanyo{'0}};
    else
        if (enable==1'b1)
                aux<={entrada_serie,aux[0:tamanyo-2]};  

assign salida_serie=modo?aux[seleccion]:aux[tamanyo-1];


endmodule
