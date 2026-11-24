-- seed_demo.sql : 36 participantes FICTICIOS para probar el dashboard. Úsalo solo en un proyecto de pruebas.
-- Requiere haber ejecutado seed.sql (periodo, consentimiento y factor). Ejecutar una sola vez.
-- Limpieza: delete from auth.users where email like 'demo%@example.invalid';  (borra en cascada sus datos)
do $$
declare v_u uuid; v_s uuid; v_a uuid; v_k uuid; v_kwh numeric; v_per int; v_f emission_factors; v_p int; v_c int;
        tipos text[] := array['estudiante','profesor','administrativo'];
begin
  select max(id) into v_p from survey_periods; select max(id) into v_c from consent_versions;
  select * into v_f from emission_factors where question_code = 'elec_kwh' order by version desc limit 1;
  for i in 1..36 loop
    insert into auth.users(id, aud, role, email) values (gen_random_uuid(), 'authenticated', 'authenticated', 'demo' || i || '@example.invalid') returning id into v_u;
    insert into profiles(id, tipo_usuario) values (v_u, tipos[1 + i % 3]);
    insert into consents(profile_id, consent_version_id) values (v_u, v_c);
    insert into surveys(profile_id, period_id, status, submitted_at) values (v_u, v_p, 'enviada', now()) returning id into v_s;
    v_kwh := round((60 + random() * 340)::numeric, 0); v_per := 1 + floor(random() * 5)::int;
    insert into activity_answers(survey_id, category, question_code, numeric_value, unit, is_estimated)
      values (v_s, 'electricidad', 'elec_kwh', v_kwh, 'kWh', random() < 0.3) returning id into v_a;
    insert into activity_answers(survey_id, category, question_code, numeric_value, unit)
      values (v_s, 'electricidad', 'elec_personas', v_per, 'personas');
    insert into calculations(survey_id, methodology_version, total_kgco2e)
      values (v_s, 'v1', round(v_kwh / v_per * v_f.factor_value, 2)) returning id into v_k;
    insert into calculation_details(calculation_id, answer_id, factor_id, activity_value, converted_value, emissions_kgco2e)
      values (v_k, v_a, v_f.id, v_kwh, v_kwh / v_per, v_kwh / v_per * v_f.factor_value);
  end loop;
end $$;
