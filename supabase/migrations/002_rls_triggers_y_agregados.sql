-- 002_rls_triggers_y_agregados.sql : RLS, auditoría, cálculo y agregados protegidos
create function is_admin() returns boolean language sql security definer set search_path = public stable
as $$ select exists(select 1 from admin_roles where user_id = auth.uid()) $$;

alter table profiles enable row level security;            alter table admin_roles enable row level security;
alter table consent_versions enable row level security;    alter table consents enable row level security;
alter table survey_periods enable row level security;      alter table surveys enable row level security;
alter table activity_answers enable row level security;    alter table emission_factors enable row level security;
alter table calculations enable row level security;        alter table calculation_details enable row level security;
alter table admin_audit_log enable row level security;     alter table data_rights_requests enable row level security;
-- admin_roles: sin políticas = nadie accede desde la API

create policy p_prof_sel on profiles for select to authenticated using (id = auth.uid());
create policy p_prof_ins on profiles for insert to authenticated with check (id = auth.uid());
create policy p_prof_upd on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy p_cv_sel on consent_versions for select to authenticated using (true);
create policy p_con_sel on consents for select to authenticated using (profile_id = auth.uid());
create policy p_con_ins on consents for insert to authenticated with check (profile_id = auth.uid());
create policy p_con_upd on consents for update to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy p_per_sel on survey_periods for select to authenticated using (true);
create policy p_per_adm on survey_periods for all to authenticated using (is_admin()) with check (is_admin());

create policy p_sur_sel on surveys for select to authenticated using (profile_id = auth.uid());
create policy p_sur_ins on surveys for insert to authenticated with check (profile_id = auth.uid()
  and exists(select 1 from consents c where c.profile_id = auth.uid() and c.revoked_at is null));
create policy p_sur_upd on surveys for update to authenticated using (profile_id = auth.uid() and status = 'borrador')
  with check (profile_id = auth.uid());

create policy p_ans_sel on activity_answers for select to authenticated
  using (exists(select 1 from surveys s where s.id = survey_id and s.profile_id = auth.uid()));
create policy p_ans_ins on activity_answers for insert to authenticated
  with check (exists(select 1 from surveys s where s.id = survey_id and s.profile_id = auth.uid() and s.status = 'borrador'));
create policy p_ans_upd on activity_answers for update to authenticated
  using (exists(select 1 from surveys s where s.id = survey_id and s.profile_id = auth.uid() and s.status = 'borrador'))
  with check (exists(select 1 from surveys s where s.id = survey_id and s.profile_id = auth.uid() and s.status = 'borrador'));

create policy p_fac_sel on emission_factors for select to authenticated using (true);
create policy p_fac_ins on emission_factors for insert to authenticated with check (is_admin()); -- sin update/delete: inmutables

create policy p_cal_sel on calculations for select to authenticated
  using (exists(select 1 from surveys s where s.id = survey_id and s.profile_id = auth.uid()));
create policy p_det_sel on calculation_details for select to authenticated
  using (exists(select 1 from calculations c join surveys s on s.id = c.survey_id
                where c.id = calculation_id and s.profile_id = auth.uid()));

create policy p_aud_sel on admin_audit_log for select to authenticated using (is_admin());
create policy p_dr_sel on data_rights_requests for select to authenticated using (profile_id = auth.uid());
create policy p_dr_ins on data_rights_requests for insert to authenticated with check (profile_id = auth.uid());

-- Auditoría de cambios administrativos (factores y periodos)
create function auditar() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into admin_audit_log(actor_id, action, entity, entity_id, before_json, after_json)
  values (auth.uid(), tg_op, tg_table_name, coalesce(new.id, old.id)::text,
          case when tg_op <> 'INSERT' then to_jsonb(old) end, case when tg_op <> 'DELETE' then to_jsonb(new) end);
  return coalesce(new, old);
end $$;
create trigger t_aud_fac after insert or update or delete on emission_factors for each row execute function auditar();
create trigger t_aud_per after insert or update or delete on survey_periods for each row execute function auditar();

-- Cálculo reproducible: kWh / personas del hogar x factor (kgCO2e por kWh). Solo categorías con factor vigente.
create function calcular_huella(p_survey uuid) returns uuid language plpgsql security definer set search_path = public as $$
declare v_calc uuid; v_pers numeric; v_total numeric; v_met text;
begin
  if not exists(select 1 from surveys where id = p_survey and profile_id = auth.uid() and status = 'enviada') then
    raise exception 'Encuesta no válida o no enviada'; end if;
  select coalesce(max(numeric_value), 1) into v_pers from activity_answers where survey_id = p_survey and question_code = 'elec_personas';
  select p.methodology_version into v_met from surveys s join survey_periods p on p.id = s.period_id where s.id = p_survey;
  delete from calculations where survey_id = p_survey;
  insert into calculations(survey_id, methodology_version, total_kgco2e) values (p_survey, v_met, 0) returning id into v_calc;
  insert into calculation_details(calculation_id, answer_id, factor_id, activity_value, converted_value, emissions_kgco2e)
  select v_calc, a.id, f.id, a.numeric_value, a.numeric_value / greatest(v_pers, 1), a.numeric_value / greatest(v_pers, 1) * f.factor_value
  from activity_answers a
  join lateral (select * from emission_factors e where e.question_code = a.question_code and e.valid_from <= current_date
                and (e.valid_to is null or e.valid_to >= current_date) order by e.version desc limit 1) f on true
  where a.survey_id = p_survey and a.question_code <> 'elec_personas';
  select coalesce(sum(emissions_kgco2e), 0) into v_total from calculation_details where calculation_id = v_calc;
  update calculations set total_kgco2e = v_total where id = v_calc;
  return v_calc;
end $$;

-- Agregados: solo administradores y solo celdas con 10 o más respuestas (regla de diseño del proyecto)
create function dashboard_resumen(p_period int, p_grupo text default null)
returns table(grupo text, categoria text, participantes bigint, promedio_kgco2e numeric, mediana_kgco2e numeric)
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  return query
  with x as (select p.tipo_usuario g, f.category c, s.id sid, sum(d.emissions_kgco2e) e
             from surveys s join profiles p on p.id = s.profile_id join calculations k on k.survey_id = s.id
             join calculation_details d on d.calculation_id = k.id join emission_factors f on f.id = d.factor_id
             where s.period_id = p_period and s.status = 'enviada' and (p_grupo is null or p.tipo_usuario = p_grupo)
             group by 1, 2, 3)
  select g, c, count(*), round(avg(e), 2), round((percentile_cont(0.5) within group (order by e))::numeric, 2)
  from x group by g, c having count(*) >= 10;
end $$;

create function dashboard_muestra(p_period int) returns bigint language plpgsql security definer set search_path = public as $$
declare n bigint;
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  select count(*) into n from surveys where period_id = p_period and status = 'enviada';
  return case when n >= 10 then n else null end;
end $$;

revoke all on function calcular_huella(uuid), dashboard_resumen(int, text), dashboard_muestra(int), is_admin() from public, anon;
grant execute on function calcular_huella(uuid), dashboard_resumen(int, text), dashboard_muestra(int), is_admin() to authenticated;
