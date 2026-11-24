CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE public.admin_roles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role_type TEXT NOT NULL CHECK (role_type IN ('admin_ambiental', 'admin_tecnico')),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo_usuario TEXT NOT NULL CHECK (tipo_usuario IN ('estudiante', 'profesor', 'administrativo')),
    campus TEXT CHECK (campus IN ('Bogota_Circunvalar', 'Bogota_Sur', 'Bogota_Federman', 'Medellin', 'Cali', 'Otro')),
    estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'supresion_solicitada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.consent_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_code TEXT NOT NULL UNIQUE,
    notice_text TEXT NOT NULL,
    effective_from DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    consent_version_id UUID NOT NULL REFERENCES public.consent_versions(id),
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    UNIQUE (user_id, consent_version_id)
);

CREATE TABLE public.survey_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    reporting_granularity TEXT NOT NULL DEFAULT 'anual' CHECK (reporting_granularity IN ('mensual', 'anual')),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_open BOOLEAN NOT NULL DEFAULT false,
    expected_population INTEGER CHECK (expected_population IS NULL OR expected_population > 0),
    population_source TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);

CREATE TABLE public.surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    period_id UUID NOT NULL REFERENCES public.survey_periods(id),
    consent_id UUID NOT NULL REFERENCES public.consents(id),
    status TEXT NOT NULL DEFAULT 'borrador' CHECK (status IN ('borrador', 'enviada')),
    submitted_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, period_id)
);

CREATE TABLE public.activity_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES public.surveys(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('electricidad', 'gas_combustibles', 'desplazamiento_campus', 'viajes_aereos', 'alimentacion', 'residuos')),
    question_code TEXT NOT NULL,
    numeric_value NUMERIC(12,4) CHECK (numeric_value IS NULL OR numeric_value >= 0),
    text_value TEXT,
    unit TEXT NOT NULL,
    is_estimated BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (survey_id, question_code)
);

CREATE TABLE public.emission_factors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    factor_code TEXT NOT NULL,
    value NUMERIC(14,6) NOT NULL CHECK (value >= 0),
    activity_unit TEXT NOT NULL,
    emission_unit TEXT NOT NULL DEFAULT 'kg CO2e',
    gas_equivalence TEXT NOT NULL DEFAULT 'CO2e',
    geography TEXT NOT NULL,
    source_name TEXT NOT NULL,
    source_url TEXT NOT NULL,
    reference_year INTEGER NOT NULL CHECK (reference_year >= 2000 AND reference_year <= 2100),
    valid_from DATE NOT NULL,
    valid_to DATE,
    method TEXT NOT NULL,
    version TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_by UUID REFERENCES auth.users(id),
    UNIQUE (factor_code, version)
);

CREATE TABLE public.calculations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES public.surveys(id) ON DELETE CASCADE,
    method_version TEXT NOT NULL,
    total_kgco2e NUMERIC(14,4) NOT NULL CHECK (total_kgco2e >= 0),
    has_estimated_inputs BOOLEAN NOT NULL DEFAULT false,
    excluded_categories JSONB NOT NULL DEFAULT '[]'::jsonb,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.calculation_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calculation_id UUID NOT NULL REFERENCES public.calculations(id) ON DELETE CASCADE,
    answer_id UUID REFERENCES public.activity_answers(id) ON DELETE SET NULL,
    factor_id UUID NOT NULL REFERENCES public.emission_factors(id),
    category TEXT NOT NULL,
    activity_value NUMERIC(14,4) NOT NULL,
    converted_value NUMERIC(14,4) NOT NULL,
    emissions_kgco2e NUMERIC(14,4) NOT NULL CHECK (emissions_kgco2e >= 0)
);

CREATE TABLE public.admin_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID NOT NULL REFERENCES auth.users(id),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    before_json JSONB,
    after_json JSONB,
    justification TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.data_rights_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    request_type TEXT NOT NULL CHECK (request_type IN ('correccion', 'retiro_consentimiento', 'supresion', 'consulta')),
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'recibida' CHECK (status IN ('recibida', 'en_revision', 'atendida', 'rechazada')),
    response_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_surveys_period_status ON public.surveys(period_id, status);
CREATE INDEX idx_answers_survey ON public.activity_answers(survey_id);
CREATE INDEX idx_calc_survey ON public.calculations(survey_id);
CREATE INDEX idx_factors_active ON public.emission_factors(category, is_active);