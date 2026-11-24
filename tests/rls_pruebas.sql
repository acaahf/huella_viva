-- Pruebas RLS manuales en SQL Editor. Reemplaza los UUID por usuarios de PRUEBA (A y B participantes, C administrador).
-- Cada bloque simula un usuario autenticado y termina con rollback.

-- 1) Participante A: solo ve sus datos (esperado: filas propias únicamente)
begin; set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"UUID_PARTICIPANTE_A","role":"authenticated"}', true);
select count(*) from surveys where profile_id <> 'UUID_PARTICIPANTE_A';          -- esperado 0
select count(*) from profiles where id <> 'UUID_PARTICIPANTE_A';                 -- esperado 0
select * from admin_roles;                                                       -- esperado: 0 filas o permiso denegado
select dashboard_resumen(1);                                                     -- esperado: ERROR No autorizado
update emission_factors set factor_value = 0 where true;                         -- esperado: 0 filas (sin política)
rollback;

-- 2) Administrador C: ve agregados, no filas individuales
begin; set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"UUID_ADMIN_C","role":"authenticated"}', true);
select * from dashboard_resumen(1);                                              -- solo celdas con 10 o más
select count(*) from activity_answers;                                           -- esperado 0 (sin acceso a respuestas)
rollback;

-- 3) Usuario no autorizado (anon): sin acceso
begin; set local role anon;
select count(*) from surveys;                                                    -- esperado: permiso denegado o 0
select dashboard_resumen(1);                                                     -- esperado: permiso denegado
rollback;
