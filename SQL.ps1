$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$sqlContent = @'
-- ============================================================================
-- MIGRACION ACTUALIZADA: PERMISOS, POLITICAS RLS Y PANEL ADMINISTRATIVO
-- Proyecto: HuellaViva UAN
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

DO $$
DECLARE pol record;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'consents') THEN
    FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'consents'
    LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.consents', pol.policyname);
    END LOOP;

    ALTER TABLE public.consents ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "consents_owner_all"
    ON public.consents
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
DECLARE pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'surveys'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.surveys', pol.policyname);
  END LOOP;
END $$;

ALTER TABLE public.surveys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "surveys_owner_all"
ON public.surveys
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DO $$
DECLARE pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'activity_answers'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.activity_answers', pol.policyname);
  END LOOP;
END $$;

ALTER TABLE public.activity_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_answers_owner_all"
ON public.activity_answers
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.surveys s
    WHERE s.id = activity_answers.survey_id AND s.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.surveys s
    WHERE s.id = activity_answers.survey_id AND s.user_id = auth.uid()
  )
);

DO $$
DECLARE pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'calculations'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.calculations', pol.policyname);
  END LOOP;
END $$;

ALTER TABLE public.calculations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "calculations_owner_all"
ON public.calculations
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.surveys s
    WHERE s.id = calculations.survey_id AND s.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.surveys s
    WHERE s.id = calculations.survey_id AND s.user_id = auth.uid()
  )
);

DO $$
DECLARE pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'calculation_details'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.calculation_details', pol.policyname);
  END LOOP;
END $$;

ALTER TABLE public.calculation_details ENABLE ROW LEVEL SECURITY;
CREATE POLICY "calculation_details_owner_all"
ON public.calculation_details
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.calculations c
    JOIN public.surveys s ON s.id = c.survey_id
    WHERE c.id = calculation_details.calculation_id AND s.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.calculations c
    JOIN public.surveys s ON s.id = c.survey_id
    WHERE c.id = calculation_details.calculation_id AND s.user_id = auth.uid()
  )
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role'
  ) THEN
    UPDATE public.profiles
    SET role = CASE
      WHEN id IN (SELECT id FROM auth.users WHERE lower(email) = 'acaamano287@uan.edu.co') THEN 'admin'
      ELSE 'usuario'
    END;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_admin'
  ) THEN
    UPDATE public.profiles
    SET is_admin = (id IN (SELECT id FROM auth.users WHERE lower(email) = 'acaamano287@uan.edu.co'));
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_data(p_period_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_es_admin boolean := false;
  v_participantes jsonb;
  v_categorias jsonb;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM auth.users u
    WHERE u.id = auth.uid()
      AND lower(u.email) = 'acaamano287@uan.edu.co'
  ) INTO v_es_admin;

  IF NOT v_es_admin THEN
    RAISE EXCEPTION 'Acceso denegado: este panel es exclusivo del administrador autorizado.';
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(t) ORDER BY t.submitted_at DESC NULLS LAST), '[]'::jsonb)
  INTO v_participantes
  FROM (
    SELECT
      s.id AS survey_id,
      u.email AS correo,
      COALESCE(p.tipo_usuario, 'estudiante') AS tipo_usuario,
      COALESCE(to_jsonb(p)->>'campus', 'Principal') AS campus,
      s.status AS estado,
      s.submitted_at,
      COALESCE(c.total_kgco2e, 0) AS total_kgco2e,
      COALESCE(c.has_estimated_inputs, false) AS tiene_estimados
    FROM public.surveys s
    JOIN auth.users u ON u.id = s.user_id
    LEFT JOIN public.profiles p ON p.id = s.user_id
    LEFT JOIN LATERAL (
      SELECT calc.total_kgco2e, calc.has_estimated_inputs
      FROM public.calculations calc
      WHERE calc.survey_id = s.id
      ORDER BY calc.id DESC
      LIMIT 1
    ) c ON true
    WHERE s.period_id = p_period_id
  ) t;

  SELECT COALESCE(jsonb_agg(row_to_json(cat)), '[]'::jsonb)
  INTO v_categorias
  FROM (
    SELECT
      cd.category AS categoria,
      ROUND(SUM(cd.emissions_kgco2e)::numeric, 2) AS total_kgco2e,
      ROUND(AVG(cd.emissions_kgco2e)::numeric, 2) AS promedio_kgco2e
    FROM public.surveys s
    JOIN LATERAL (
      SELECT calc.id
      FROM public.calculations calc
      WHERE calc.survey_id = s.id
      ORDER BY calc.id DESC
      LIMIT 1
    ) ult_calc ON true
    JOIN public.calculation_details cd ON cd.calculation_id = ult_calc.id
    WHERE s.period_id = p_period_id
      AND s.status = 'enviada'
    GROUP BY cd.category
    ORDER BY SUM(cd.emissions_kgco2e) DESC
  ) cat;

  RETURN jsonb_build_object(
    'participantes', v_participantes,
    'categorias', v_categorias
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_data(uuid) TO authenticated;
'@

$destPath = Join-Path (Get-Location) "supabase\migrations\004_rls_y_admin_actualizado.sql"
[System.IO.File]::WriteAllText($destPath, $sqlContent, $utf8NoBom)

git add supabase/migrations/004_rls_y_admin_actualizado.sql
git commit -m "Agrega migracion 004 con RLS y RPC administrativo actualizado en UTF-8"
git push