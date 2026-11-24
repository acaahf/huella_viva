# Registro de pruebas (completar con fecha, responsable y resultado reales)

| ID | Prueba | Cómo | Esperado | Resultado | Fecha | Responsable |
|---|---|---|---|---|---|---|
| T-01 | Cálculo y validaciones | `node --test tests/calculo.test.mjs` | Todas pasan | | | |
| T-02 | RLS participante | bloque 1 de `rls_pruebas.sql` | 0 filas ajenas; dashboard falla | | | |
| T-03 | RLS administrador | bloque 2 | Agregados sí; respuestas no | | | |
| T-04 | RLS no autorizado | bloque 3 | Permiso denegado | | | |
| T-05 | Privacidad del dashboard | con menos de 10 respuestas | Sin cifras | | | |
| T-06 | Consentimiento obligatorio | encuesta sin aceptar | Redirige y no guarda | | | |
| T-07 | Reabrir y reenviar | encuesta enviada | Cálculo se rehace | | | |
| T-08 | CSV seguro | descargar y abrir | Solo agregados | | | |
| T-09 | Accesibilidad | teclado + lector + contraste 4.5:1 | Sin bloqueos | | | |
| T-10 | Responsive | 360, 768 y 1280 px | Sin scroll horizontal de página | | | |
