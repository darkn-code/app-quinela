-- apply_demo.sql
-- Punto de entrada para aplicar el backend completo de demo con psql.
-- Ejecutar desde Docker Compose:
-- docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/apply_demo.sql'

\set ON_ERROR_STOP on

\echo 'Applying schema.sql'
\ir schema.sql

\echo 'Applying functions.sql'
\ir functions.sql

\echo 'Applying policies.sql'
\ir policies.sql

\echo 'Applying views.sql'
\ir views.sql

\echo 'Applying seeds/demo_data.sql'
\ir seeds/demo_data.sql

\echo 'Supabase demo backend applied successfully.'
