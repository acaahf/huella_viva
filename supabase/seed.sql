-- seed.sql : SOLO datos sintéticos / públicos. Sin datos personales.
insert into consent_versions(version, texto, purpose) values
('v1-borrador',
 'La Universidad Antonio Nariño, como responsable que deberá identificarse y validar este aviso institucionalmente, solicita sus respuestas para estimar su huella de carbono y generar informes individuales y estadísticas agregadas de la comunidad universitaria. La participación es voluntaria. Las respuestas se tratarán para la finalidad informada y se protegerán con controles de acceso. Puede consultar, actualizar o solicitar la atención de sus derechos por el canal institucional indicado: [POR COMPLETAR CON LA INSTANCIA INSTITUCIONAL]. Consulte el aviso completo de privacidad antes de continuar. (Borrador académico, no constituye concepto legal.)',
 'Estimar huella de carbono individual y estadísticas agregadas (prototipo académico)');

insert into survey_periods(name, start_date, end_date, methodology_version, status)
values ('Periodo de prueba (mensual, datos ficticios)', '2026-11-01', '2026-12-31', 'v1', 'abierto');

-- Único factor cargado: SIN para inventarios de GEI 2024, UPME. 0,220 tCO2e/MWh = 0,220 kgCO2e/kWh.
-- Fecha de consulta: 2026-11-23. Verificar vigencia en la fuente antes de usar en un piloto real.
insert into emission_factors(category, question_code, factor_value, unit_activity, unit_emission, geography,
  source, source_url, reference_year, valid_from, version)
values ('electricidad', 'elec_kwh', 0.220, 'kWh', 'kgCO2e', 'Colombia (SIN)',
  'UPME - Factores de emisión del SIN 2024 (factor para inventarios de GEI)',
  'https://docs.upme.gov.co/Normatividad/Soporte_calculo_Factor_de_Emision_2024.pdf', 2024, '2026-01-01', 1);
