# HuellaViva UAN

Prototipo académico para estimar la huella de carbono de la comunidad universitaria (UAN).
**No es** un inventario institucional verificado, ni certificación, ni compensación, ni resultado oficial de RENARE.

## Qué incluye
Acceso de participante, consentimiento versionado, encuesta con validación, cálculo reproducible con factores versionados (SQL), informe individual, solicitudes de derechos, dashboard agregado (mínimo 10 respuestas) y exportación CSV. HTML, CSS y JS están en archivos separados; sin build.

## Puesta en marcha
1. Crea un proyecto en [Supabase](https://supabase.com).
2. En *SQL Editor* ejecuta en orden: `supabase/migrations/001_esquema_base.sql`, `002_rls_triggers_y_agregados.sql` y `supabase/seed.sql` (solo datos sintéticos).
3. Copia la URL y la clave **anon** (Project Settings → API) a `src/js/config.js`. Nunca uses `service_role` en el navegador.
4. Copia `.env.example` a `.env` (solo si usarás CLI/migraciones; está en `.gitignore`).
5. Authentication → Providers → Email: para probar rápido desactiva "Confirm email".
6. Sirve la carpeta: `cd src` y `python -m http.server 8080`; abre http://localhost:8080
7. Primer administrador (SQL Editor, después de registrarte): `insert into admin_roles(user_id,rol) select id,'ambiental' from auth.users where email='TU_CORREO';`
8. Pruebas del cálculo: `node --test tests/calculo.test.mjs`. Pruebas RLS: `tests/rls_pruebas.sql`.

## Límite honesto del prototipo
Solo la categoría **electricidad** tiene factor con fuente verificada (UPME, SIN 2024). Transporte, gas, vuelos, alimentación y residuos quedan **sin factor verificado**: no se incluyen en el total hasta cargar factores con fuente y año (ver `docs/`). La interfaz de gestión de factores y periodos se hace por SQL; el esquema ya los versiona y audita.

## Estructura
`docs/` análisis y diseño · `src/` aplicación · `supabase/` migraciones y seed · `tests/` pruebas · `assets/` logo

## Ampliación
Ejecuta además en el SQL Editor: `supabase/migrations/003_administracion_y_ajustes.sql`. Para probar el dashboard, en un proyecto de pruebas ejecuta `supabase/seed_demo.sql` (36 participantes ficticios). Nuevas páginas: factores, periodos y solicitudes. Documentos: `docs/04` a `docs/06`.
