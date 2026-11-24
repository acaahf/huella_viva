# Requisitos y trazabilidad

Estado: **Hecho** = implementado en este prototipo; **Parcial** = base lista, falta completar; **Pendiente** = no implementado.

| Código | Requisito | Prioridad | Estado | Código / diseño | Prueba |
|---|---|---|---|---|---|
| RF-01 | Consentimiento antes de guardar; versión del aviso | Must | Hecho | consentimiento.js, `consents`, policy `p_sur_ins` | rls_pruebas.sql |
| RF-02 | Grupo poblacional y acceso seguro, solo datos propios | Must | Hecho | auth.js, `profiles`, RLS | rls_pruebas.sql |
| RF-03 | Responder, guardar y editar (borrador) en periodo habilitado | Must | Hecho | encuesta.js, validaciones.js, CHECK en BD | calculo.test.mjs |
| RF-04 | Cálculo con factores versionados, reconstruible | Must | Hecho | `calcular_huella()`, `calculation_details` | calculo.test.mjs |
| RF-05 | Informe con total, desglose, fuentes, límites | Must | Hecho | informe.js | manual |
| RF-06 | Dashboard agregado, mínimo 10 respuestas | Must | Hecho | `dashboard_resumen()`, dashboard.js | rls_pruebas.sql |
| RF-07 | Gestión de factores/periodos con historial | Should | Parcial | Auditoría y versionado en SQL; falta interfaz | manual |
| RF-08 | Exportar CSV agregado | Should | Hecho | exportCsv.js | manual |
| RF-09 | Solicitudes de corrección/supresión y estado | Should | Hecho | derechos.js, `data_rights_requests` | manual |
| RF-10 | Tamaño y cobertura de la muestra | Should | Hecho | `dashboard_muestra()` (sin extrapolar) | manual |

## RNF medibles (a verificar en el piloto)
- RLS activa en 100 % de las tablas expuestas (comprobar con `select relname, relrowsecurity from pg_class`).
- 0 secretos en el repositorio (revisar con `git log -p | findstr /i service_role`).
- Contraste mínimo 4.5:1 y navegación por teclado completa (WCAG 2.1 AA).
- Responsive en 360, 768 y 1280 px. Informe visible en menos de 2 s con 4G.
- Respaldo: exportación periódica del proyecto Supabase, con prueba de restauración documentada.

## Historias de usuario (muestra INVEST)
- Como estudiante quiero registrar el consumo eléctrico de mi hogar para ver mi estimación. *Criterios:* kWh entre 0 y 20000; personas entre 1 y 30; sin consentimiento no se guarda; el informe muestra factor, fuente y año.
- Como administrador ambiental quiero ver promedios por grupo para priorizar acciones. *Criterios:* celdas con menos de 10 respuestas ocultas; CSV sin identificadores.

## Gestión de cambios (plantilla; el equipo debe registrar su evidencia real)
| ID | Solicitud | Solicitante | Impacto | Decisión |
|---|---|---|---|---|
| CR-01 | Permitir "no conozco mi consumo" y estimar con rango de factura | Área ambiental | Pregunta nueva, factor de tarifa por zona/año, fórmula, BD (`is_estimated`), consentimiento, informe, pruebas | Por decidir |
| CR-02 | Agregar categoría de transporte a campus | Área ambiental | Cargar factor FECOC/UPME con fuente, nuevas preguntas, validaciones, pruebas | Por decidir |

La que se apruebe debe reflejarse en backlog, diseño y una prueba (actualizar esta tabla y `calculo.test.mjs`).
