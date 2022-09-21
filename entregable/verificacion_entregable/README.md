# instrucciones y comentarios profesores

En este directorio deberían estar todos los ficheros fuente y scripts necesarios para la simulacion-verificación de vuestra FIFO.

En cuanto a las instrucciones para la ejecución del script completo de verificación debería ser explicado en el siguiente apartado de este Readme

# instrucciones y comentarios de los alumnos
Realizado por Marcos Ibáñez y Arnau Mora. Grupo B1.

## ejecución del script de verificacion
## Tareas
### `reset`
Reincia la memoria y todos los punteros.

### `empty_check`
Comprueba que la memoria está vacía. Se usa después de `reset` para asegurarnos de que funciona correctamente y reinicia la memoria.

### `escritura`
Comprueba que la escritura funciona correctamente. Para ello escribe un valor de 8 bits aleatorio generado con la función `aleatorio`. Después, comprueba que el contador de uso `USE_DW` ha incrementado, lee el valor de la memoria, y comprueba que sea igual al que se supone que se ha escrito. Finalmente, comprueba que `USE_DW` tiene el valor que tenía al principio, es decir, que la lectura ha reducido este valor en `1`.
