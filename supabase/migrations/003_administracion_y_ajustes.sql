-- 003_administracion_y_ajustes.sql : ejecutar después de 002
alter table emission_factors add column if not exists justificacion text;

-- Participante: reabrir su encuesta mientras el periodo siga abierto (borra el cálculo; debe reenviar)
create function reabrir_encuesta(p_survey uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists(select 1 from surveys s join survey_periods p on p.id = s.period_id
                where s.id = p_survey and s.profile_id = auth.uid() and p.status = 'abierto') then
    raise exception 'No se puede reabrir: periodo cerrado o encuesta ajena'; end if;
  delete from calculations where survey_id = p_survey;
  update surveys set status = 'borrador', submitted_at = null, updated_at = now() where id = p_survey;
end $$;

-- Admin: publicar nueva versión de un factor (cierra la anterior; los cálculos previos conservan su factor_id)
create function publicar_factor(p_category text, p_question text, p_valor numeric, p_unidad text, p_geo text,
  p_fuente text, p_url text, p_anio int, p_desde date, p_just text) returns int
language plpgsql security definer set search_path = public as $$
declare v int; v_id int;
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  if coalesce(trim(p_just), '') = '' or p_url !~ '^https://' or p_valor < 0 then
    raise exception 'Se requiere valor no negativo, justificación y URL https de la fuente'; end if;
  select coalesce(max(version), 0) + 1 into v from emission_factors where question_code = p_question;
  update emission_factors set valid_to = p_desde - 1 where question_code = p_question and valid_to is null;
  insert into emission_factors(category, question_code, factor_value, unit_activity, geography, source, source_url,
    reference_year, valid_from, version, approved_by, justificacion)
  values (p_category, p_question, p_valor, p_unidad, p_geo, p_fuente, p_url, p_anio, p_desde, v, auth.uid(), p_just)
  returning id into v_id;
  return v_id;
end $$;

-- Admin: atender solicitudes de derechos (sin exponer la identidad; la atención va por el canal institucional)
create function admin_solicitudes() returns table(id uuid, tipo text, estado text, detalle text, created_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  return query select r.id, r.tipo, r.estado, r.detalle, r.created_at from data_rights_requests r order by r.created_at desc;
end $$;

create function admin_estado_solicitud(p_id uuid, p_estado text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  if p_estado not in ('recibida','en_tramite','atendida') then raise exception 'Estado inválido'; end if;
  update data_rights_requests set estado = p_estado where id = p_id;
  insert into admin_audit_log(actor_id, action, entity, entity_id, after_json)
  values (auth.uid(), 'UPDATE', 'data_rights_requests', p_id::text, jsonb_build_object('estado', p_estado));
end $$;

-- Distribución del total individual (rangos con 10 o más personas)
create function dashboard_distribucion(p_period int) returns table(rango text, participantes bigint)
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  return query
  with t as (select k.total_kgco2e v from calculations k join surveys s on s.id = k.survey_id
             where s.period_id = p_period and s.status = 'enviada')
  select case when v < 25 then '0 a 25' when v < 50 then '25 a 50' when v < 100 then '50 a 100' else '100 o más' end as r,
         count(*) from t group by 1 having count(*) >= 10 order by min(v);
end $$;

revoke all on function reabrir_encuesta(uuid), publicar_factor(text,text,numeric,text,text,text,text,int,date,text),
  admin_solicitudes(), admin_estado_solicitud(uuid,text), dashboard_distribucion(int) from public, anon;
grant execute on function reabrir_encuesta(uuid), publicar_factor(text,text,numeric,text,text,text,text,int,date,text),
  admin_solicitudes(), admin_estado_solicitud(uuid,text), dashboard_distribucion(int) to authenticated;
