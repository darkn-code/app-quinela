# Backend / Supabase

Carpeta de configuracion SQL para Supabase.

## Estructura

```text
backend/
├── README.md
└── supabase/
    ├── apply_demo.sql
    ├── schema.sql
    ├── functions.sql
    ├── policies.sql
    ├── views.sql
    └── seeds/
        └── demo_data.sql
```

## Orden de ejecucion

Para una demo separada, aplicar todo con un solo comando desde Docker Compose:

```bash
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/apply_demo.sql'
```

Ese comando usa el servicio `supabase-db-client`, que ejecuta `psql` dentro de Docker. No requiere instalar `psql` en el host.

`SUPABASE_DB_URL` debe estar definido en `.env` o en el entorno local. No commitear `.env`.

Internamente, `apply_demo.sql` ejecuta los scripts en este orden:

1. `schema.sql`
2. `functions.sql`
3. `policies.sql`
4. `views.sql`
5. `seeds/demo_data.sql`

Tambien se pueden ejecutar de forma individual para depurar:

```bash
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/schema.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/functions.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/policies.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/views.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/seeds/demo_data.sql'
```

La documentacion completa esta en `docs/backend_supabase.md`.
