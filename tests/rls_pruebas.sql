-- Pruebas negativas de RLS
SET LOCAL ROLE anon;
SELECT count(*) FROM public.surveys; -- Esperado: 0

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
INSERT INTO public.admin_roles (user_id, role_type) VALUES ('11111111-1111-1111-1111-111111111111', 'admin_tecnico');
-- Esperado: ERROR violacion de politica RLS