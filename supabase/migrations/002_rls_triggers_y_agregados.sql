CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.admin_roles WHERE user_id = auth.uid());
$$;

ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consent_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emission_factors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calculation_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_rights_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_own" ON public.profiles FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "admin_roles_select_own" ON public.admin_roles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "consent_versions_read" ON public.consent_versions FOR SELECT TO authenticated USING (true);
CREATE POLICY "consents_own" ON public.consents FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "periods_read" ON public.survey_periods FOR SELECT TO authenticated USING (true);
CREATE POLICY "periods_admin" ON public.survey_periods FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "factors_read" ON public.emission_factors FOR SELECT TO authenticated USING (true);
CREATE POLICY "factors_admin_ins" ON public.emission_factors FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "factors_admin_upd" ON public.emission_factors FOR UPDATE USING (public.is_admin());
CREATE POLICY "surveys_own" ON public.surveys FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "answers_own" ON public.activity_answers FOR ALL
  USING (EXISTS (SELECT 1 FROM public.surveys s WHERE s.id = survey_id AND s.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.surveys s WHERE s.id = survey_id AND s.user_id = auth.uid()));
CREATE POLICY "calculations_own" ON public.calculations FOR ALL
  USING (EXISTS (SELECT 1 FROM public.surveys s WHERE s.id = survey_id AND s.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.surveys s WHERE s.id = survey_id AND s.user_id = auth.uid()));
CREATE POLICY "calc_details_own" ON public.calculation_details FOR ALL
  USING (EXISTS (SELECT 1 FROM public.calculations c JOIN public.surveys s ON s.id = c.survey_id WHERE c.id = calculation_id AND s.user_id = auth.uid()));
CREATE POLICY "audit_admin_sel" ON public.admin_audit_log FOR SELECT USING (public.is_admin());
CREATE POLICY "audit_admin_ins" ON public.admin_audit_log FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "rights_sel" ON public.data_rights_requests FOR SELECT USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY "rights_ins" ON public.data_rights_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "rights_upd" ON public.data_rights_requests FOR UPDATE USING (public.is_admin());

CREATE OR REPLACE FUNCTION public.prevent_used_factor_mutation()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (OLD.value IS DISTINCT FROM NEW.value OR OLD.activity_unit IS DISTINCT FROM NEW.activity_unit) THEN
    IF EXISTS (SELECT 1 FROM public.calculation_details WHERE factor_id = OLD.id) THEN
      RAISE EXCEPTION 'Factor inmutable: ya fue utilizado en calculos. Cree una nueva version.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_factor_immutability
BEFORE UPDATE ON public.emission_factors FOR EACH ROW EXECUTE FUNCTION public.prevent_used_factor_mutation();

CREATE OR REPLACE FUNCTION public.get_aggregated_metrics(
    p_period_id UUID, p_campus TEXT DEFAULT NULL, p_tipo_usuario TEXT DEFAULT NULL, p_min_cell INTEGER DEFAULT 10
)
RETURNS TABLE (
    tipo_usuario TEXT, campus TEXT, participantes BIGINT,
    promedio_kgco2e NUMERIC, mediana_kgco2e NUMERIC, oculto_por_privacidad BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol administrativo autorizado.';
  END IF;
  RETURN QUERY
  WITH base AS (
    SELECT p.tipo_usuario, COALESCE(p.campus, 'No reportado') AS campus, c.total_kgco2e
    FROM public.calculations c
    JOIN public.surveys s ON s.id = c.survey_id AND s.status = 'enviada'
    JOIN public.profiles p ON p.id = s.user_id
    WHERE s.period_id = p_period_id
      AND (p_campus IS NULL OR p.campus = p_campus)
      AND (p_tipo_usuario IS NULL OR p.tipo_usuario = p_tipo_usuario)
  )
  SELECT b.tipo_usuario, b.campus, COUNT(*) AS participantes,
    CASE WHEN COUNT(*) >= p_min_cell THEN ROUND(AVG(b.total_kgco2e), 2) ELSE NULL END,
    CASE WHEN COUNT(*) >= p_min_cell THEN ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY b.total_kgco2e)::numeric, 2) ELSE NULL END,
    (COUNT(*) < p_min_cell)
  FROM base b GROUP BY b.tipo_usuario, b.campus;
END;
$$;