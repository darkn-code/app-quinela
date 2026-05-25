-- demo_data.sql
-- Partidos de ejemplo para validar la demo.
-- Ejecutar al final. No crea usuarios ni credenciales.

insert into public.matches (
  id,
  home_team,
  away_team,
  starts_at,
  status,
  home_score,
  away_score
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'Mexico',
    'South Africa',
    '2026-06-11 19:00:00+00',
    'scheduled',
    null,
    null
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'United States',
    'Canada',
    '2026-06-12 01:00:00+00',
    'scheduled',
    null,
    null
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    'Brazil',
    'Germany',
    '2026-06-13 22:00:00+00',
    'scheduled',
    null,
    null
  ),
  (
    '44444444-4444-4444-8444-444444444444',
    'Argentina',
    'Spain',
    '2026-06-14 20:00:00+00',
    'scheduled',
    null,
    null
  ),
  (
    '55555555-5555-4555-8555-555555555555',
    'France',
    'Japan',
    '2026-06-15 18:00:00+00',
    'scheduled',
    null,
    null
  ),
  (
    '66666666-6666-4666-8666-666666666666',
    'England',
    'Uruguay',
    '2026-06-16 23:00:00+00',
    'scheduled',
    null,
    null
  )
on conflict (id) do update
set home_team = excluded.home_team,
  away_team = excluded.away_team,
  starts_at = excluded.starts_at,
  status = excluded.status,
  home_score = excluded.home_score,
  away_score = excluded.away_score;

-- Para probar resultados, crear predicciones desde el frontend con usuarios reales
-- y despues ejecutar una llamada RPC a public.set_match_result desde un usuario admin.
