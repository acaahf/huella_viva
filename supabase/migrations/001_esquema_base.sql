-- 001_esquema_base.sql : esquema HuellaViva UAN
create extension if not exists pgcrypto;

create table profiles(
  id uuid primary key references auth.users on delete cascade,
  tipo_usuario text not null check (tipo_usuario in ('estudiante','profesor','administrativo')),
  campus text, estado text not null default 'activo', created_at timestamptz not null default now());

-- Rol administrativo: tabla sin políticas RLS (solo editable por SQL/service_role, nunca por el usuario)
create table admin_roles(user_id uuid primary key references auth.users on delete cascade,
  rol text not null check (rol in ('ambiental','tecnico')));

create table consent_versions(id serial primary key, version text unique not null, texto text not null,
  purpose text not null, valid_from date not null default current_date, active boolean not null default true);

create table consents(id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  consent_version_id int not null references consent_versions,
  accepted_at timestamptz not null default now(), revoked_at timestamptz);

create table survey_periods(id serial primary key, name text not null, start_date date not null,
  end_date date not null, methodology_version text not null default 'v1',
  status text not null default 'abierto' check (status in ('abierto','cerrado')), check (end_date >= start_date));

create table surveys(id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  period_id int not null references survey_periods,
  status text not null default 'borrador' check (status in ('borrador','enviada')),
  submitted_at timestamptz, updated_at timestamptz not null default now(), unique(profile_id, period_id));

create table activity_answers(id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references surveys on delete cascade,
  category text not null, question_code text not null,
  numeric_value numeric check (numeric_value between 0 and 100000), text_value text,
  unit text not null, is_estimated boolean not null default false, unique(survey_id, question_code));

-- Factores versionados e inmutables: para cambiar un valor se inserta una versión nueva
create table emission_factors(id serial primary key, category text not null, question_code text not null,
  factor_value numeric not null check (factor_value >= 0),
  unit_activity text not null, unit_emission text not null default 'kgCO2e',
  geography text not null, source text not null, source_url text not null,
  reference_year int not null, valid_from date not null, valid_to date,
  version int not null default 1, approved_by uuid references auth.users,
  loaded_at timestamptz not null default now(), unique(question_code, version));

create table calculations(id uuid primary key default gen_random_uuid(),
  survey_id uuid not null unique references surveys on delete cascade,
  methodology_version text not null, total_kgco2e numeric not null, calculated_at timestamptz not null default now());

create table calculation_details(id uuid primary key default gen_random_uuid(),
  calculation_id uuid not null references calculations on delete cascade,
  answer_id uuid not null references activity_answers on delete cascade,
  factor_id int not null references emission_factors,
  activity_value numeric not null, converted_value numeric not null, emissions_kgco2e numeric not null);

create table admin_audit_log(id bigserial primary key, actor_id uuid, action text not null, entity text not null,
  entity_id text, before_json jsonb, after_json jsonb, created_at timestamptz not null default now());

create table data_rights_requests(id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles on delete cascade,
  tipo text not null check (tipo in ('correccion','retiro','supresion')),
  detalle text check (char_length(detalle) <= 1000),
  estado text not null default 'recibida' check (estado in ('recibida','en_tramite','atendida')),
  created_at timestamptz not null default now());

create index on surveys(period_id); create index on activity_answers(survey_id);
create index on calculation_details(calculation_id); create index on emission_factors(question_code, valid_from);
