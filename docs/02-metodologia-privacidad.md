# Metodología, encuesta y privacidad

## Alcance y advertencia
Estimador educativo. No es inventario institucional verificado, certificación, compensación ni resultado RENARE. La estimación individual es una adaptación académica de GHG Protocol / ISO 14064-1.

## Encuesta (periodo mensual de reporte; unidad kWh)
| Categoría | Estado | Pregunta | Unidad | Obligatoria |
|---|---|---|---|---|
| Electricidad | Activa | Consumo del hogar en el periodo | kWh | Sí |
| Electricidad | Activa | Personas que comparten el consumo | personas | Sí |
| Gas y combustibles | Sin factor verificado | Pendiente | - | - |
| Transporte a campus | Sin factor verificado | Pendiente | - | - |
| Viajes aéreos | Sin factor verificado | Pendiente | - | - |
| Alimentación / consumo / residuos | Sin factor verificado (opcionales) | Pendiente | - | - |

**Datos faltantes:** una categoría sin respuesta o sin factor no suma al total y se declara en el informe. No se imputan valores.

## Cálculo
`kg CO2e = (kWh del hogar / personas del hogar) x factor (kg CO2e/kWh)`. Total = suma de categorías con factor vigente. Conversión: 1 tCO2e/MWh = 1 kgCO2e/kWh.

Factor cargado: SIN para inventarios de GEI, 2024 = 0,220 tCO2e/MWh (UPME). Consultado el 2026-11-23; verificar vigencia en la fuente antes de un piloto. Los factores son versionados e inmutables; cada cálculo guarda el factor exacto usado. **Incertidumbre:** factor promedio anual de red, dato del hogar a veces estimado, reparto por persona uniforme.

## Privacidad (Ley 1581 de 2012, Decreto 1074 de 2015)
- **Minimización:** sin documento, dirección, placa ni rutas. Perfil mínimo (grupo, campus opcional).
- **Finalidad y transparencia:** aviso versionado y registrado con fecha. Responsable y canal quedan **por completar** con la instancia institucional; el texto es borrador, no concepto legal.
- **Acceso del titular:** informe propio y solicitudes de corrección/retiro/supresión con estado.
- **Seudonimización:** IDs internos; dashboard y CSV agregados sin identidad; celdas menores a 10 ocultas (regla de diseño, no umbral legal).
- **Seguridad:** RLS en todas las tablas, rol admin fuera del alcance del usuario, funciones de agregados restringidas, clave anon solo en cliente, secretos fuera de Git.
- **Retención (propuesta académica):** conservar hasta el cierre del curso y luego anonimizar o eliminar; validar con la política institucional.

## Riesgos principales
| Riesgo | Mitigación |
|---|---|
| Reidentificación en grupos pequeños | Umbral de 10 y sin filtros que lo eludan |
| Fuga de claves | .gitignore, `.env.example`, solo clave anon en cliente |
| Elevación de privilegios | `admin_roles` sin políticas; funciones con `is_admin()` |
| Factores incorrectos | Fuente, año y versión por factor; auditoría |
