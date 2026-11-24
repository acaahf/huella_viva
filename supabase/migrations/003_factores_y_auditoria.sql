-- 003_factores_y_auditoria.sql
-- Auditoria automatica en cambios de factores y periodos + carga de factores documentados

CREATE OR REPLACE FUNCTION public.log_admin_changes()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    INSERT INTO public.admin_audit_log (actor_user_id, table_name, record_id, action, before_json, after_json, justification)
    VALUES (
      auth.uid(),
      TG_TABLE_NAME,
      COALESCE(NEW.id, OLD.id),
      TG_OP,
      CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
      CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
      'Operacion administrativa registrada desde interfaz web'
    );
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_factors ON public.emission_factors;
CREATE TRIGGER trg_audit_factors
AFTER INSERT OR UPDATE ON public.emission_factors
FOR EACH ROW EXECUTE FUNCTION public.log_admin_changes();

DROP TRIGGER IF EXISTS trg_audit_periods ON public.survey_periods;
CREATE TRIGGER trg_audit_periods
AFTER INSERT OR UPDATE ON public.survey_periods
FOR EACH ROW EXECUTE FUNCTION public.log_admin_changes();

-- Factores adicionales documentados (UPME / FECOC+ Colombia)
INSERT INTO public.emission_factors (
  category, factor_code, value, activity_unit, emission_unit, gas_equivalence,
  geography, source_name, source_url, reference_year, valid_from, method, version, is_active
) VALUES
(
  'gas_combustibles', 'GAS_NAT_CO', 1.960000, 'm3', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - Calculadora FECOC+ Gas Natural Residencial (referencia academica)',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 1', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_BUS_CO', 0.089000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - Transporte Sostenible / Referencia pasajeros-km transporte publico',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_AUTO_CO', 0.192000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - FECOC+ Vehiculo particular gasolina promedio',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_MOTO_CO', 0.072000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - FECOC+ Motocicleta gasolina promedio',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_BICI_PIE', 0.000000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'Modo activo sin emisiones directas de combustion',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
)
ON CONFLICT (factor_code, version) DO NOTHING;