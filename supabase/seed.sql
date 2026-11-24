INSERT INTO public.consent_versions (version_code, notice_text, effective_from, is_active) VALUES (
  'v1.0-academico',
  'La Universidad Antonio Nariño, como responsable que debera identificarse y validar este aviso institucionalmente, solicita sus respuestas para estimar su huella de carbono y generar informes individuales y estadisticas agregadas de la comunidad universitaria. La participacion es voluntaria. Las respuestas se trataran para la finalidad informada y se protegeran con controles de acceso. Puede consultar, actualizar o solicitar la atencion de sus derechos por el canal institucional indicado ([POR COMPLETAR CON LA INSTANCIA INSTITUCIONAL]). Consulte el aviso completo de privacidad antes de continuar. Este texto no constituye concepto legal.',
  '2026-01-01', true
);

INSERT INTO public.survey_periods (code, name, reporting_granularity, starts_at, ends_at, is_open, expected_population, population_source) VALUES (
  '2026-2', 'Diagnostico Academico 2026-2 (Anualizado)', 'anual',
  '2026-08-01 00:00:00-05', '2026-12-15 23:59:59-05', true, NULL,
  'Sin denominador oficial cargado'
);

INSERT INTO public.emission_factors (
  category, factor_code, value, activity_unit, emission_unit, gas_equivalence,
  geography, source_name, source_url, reference_year, valid_from, method, version, is_active
) VALUES (
  'electricidad', 'ELEC_SIN_CO', 0.220000, 'kWh', 'kg CO2e', 'CO2e',
  'Colombia (SIN)', 'UPME - Factor de emision de CO2 del SIN 2024 (0,220 tCO2eq/MWh)',
  'https://www.upme.gov.co/simec/oferta-y-demanda/transicion-energetica-justa/cambioclimatico/calculo-del-factor-de-emision-de-co2-del-sin/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 2', '2024.1', true
);