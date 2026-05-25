# Backend / Supabase

Supabase es el backend inicial de la demo. No hay backend Python, Django, FastAPI ni servidor propio en esta etapa.

## Archivos SQL

- `backend/supabase/schema.sql`: tablas, restricciones e indices.
- `backend/supabase/functions.sql`: funciones, RPC y triggers.
- `backend/supabase/policies.sql`: politicas RLS.
- `backend/supabase/views.sql`: vistas para frontend y ranking.
- `backend/supabase/seeds/demo_data.sql`: partidos de ejemplo.
- `backend/supabase/apply_demo.sql`: script psql que aplica todo lo anterior en orden.

## Modelo de datos

### `profiles`

Perfil publico basico de cada usuario autenticado.

- `id`: `auth.users.id`.
- `display_name`: nombre visible en ranking.
- `created_at`, `updated_at`.

La funcion `handle_new_user_profile()` crea un perfil automaticamente cuando Supabase Auth crea un usuario.

### `admin_users`

Lista simple de administradores.

- `user_id`: `auth.users.id`.
- `created_at`.

Esta tabla se administra desde SQL Editor, Supabase Dashboard o con service role. No se expone al frontend normal.

### `matches`

Partidos y resultados reales. Para la demo los resultados viven aqui, sin tabla separada.

- Equipos: `home_team`, `away_team`.
- Inicio: `starts_at` con zona horaria.
- Estado: `scheduled`, `live`, `finished`.
- Resultado real: `home_score`, `away_score`.

Solo admins pueden insertar o actualizar partidos/resultados.

### `predictions`

Prediccion de marcador de un usuario para un partido.

- `user_id`: usuario autenticado.
- `match_id`: partido.
- `predicted_home_score`, `predicted_away_score`.
- `points`: calculado por la base de datos.

Existe una restriccion unica `user_id, match_id` para impedir duplicados.
`user_id` usa `auth.uid()` como default, por lo que el frontend autenticado puede crear o hacer `upsert` sin enviar el UUID del usuario.

## Reglas de seguridad

RLS queda activo en todas las tablas publicas.

- Usuarios autenticados pueden leer partidos.
- Usuarios autenticados solo leen, crean, editan o borran sus propias predicciones.
- Las predicciones solo pueden crearse o editarse si el partido sigue `scheduled` y `starts_at > now()`.
- Usuarios normales no pueden modificar partidos ni resultados.
- Admins se validan contra `admin_users`.
- Los puntos no se aceptan desde el cliente: triggers los recalculan en base al resultado real.
- Los grants SQL para `authenticated` se declaran explicitamente en `policies.sql`; las politicas RLS siguen siendo el filtro efectivo por usuario.

## Puntuacion

La funcion `calculate_prediction_points()` aplica:

- Marcador exacto: 5 puntos.
- Resultado correcto, ganador o empate: 3 puntos.
- Error: 0 puntos.

Cuando un admin actualiza un resultado en `matches`, el trigger `recalculate_predictions_after_result` recalcula las predicciones de ese partido.

## Ranking

La vista `ranking_general` entrega:

- `rank_position`
- `user_id`
- `display_name`
- `total_points`
- `exact_scores`
- `correct_results`
- `predictions_count`

El ranking ordena por puntos totales, luego marcadores exactos y despues nombre visible.

La vista `ranking_general` es una lectura agregada global para usuarios autenticados. Las vistas `match_cards` y `my_predictions` usan `security_invoker` para respetar RLS sobre las tablas base; `my_predictions` queda filtrada a las predicciones del usuario autenticado.

## Contrato para frontend autenticado

- Leer partidos: `select * from public.match_cards order by starts_at`.
- Leer predicciones propias: `select * from public.my_predictions order by starts_at`.
- Leer ranking: `select * from public.ranking_general order by rank_position`.
- Crear o actualizar prediccion propia: `upsert` en `public.predictions` con `onConflict: 'user_id,match_id'`.

Payload minimo para `upsert`:

```json
{
  "match_id": "11111111-1111-4111-8111-111111111111",
  "predicted_home_score": 2,
  "predicted_away_score": 1
}
```

La base asigna `user_id = auth.uid()` si no se envia. Si el cliente envia otro `user_id`, RLS rechaza la escritura. La base tambien recalcula `points`, aunque el cliente intente enviarlo.

## Orden de ejecucion en Supabase

Para la demo separada, el camino recomendado es Docker Compose. El servicio `supabase-db-client` usa la imagen `postgres:16-alpine` solo como cliente SQL y evita instalar `psql` en el host:

```bash
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/apply_demo.sql'
```

`SUPABASE_DB_URL` debe estar definido en `.env` o en el entorno local antes de correr el comando. No se debe commitear `.env`.

El script `apply_demo.sql` usa `\ir` de `psql`, por eso debe ejecutarse con `psql` y no pegarse en el SQL Editor.

En el SQL Editor de Supabase, ejecutar manualmente los archivos en este orden:

```sql
-- 1
-- contenido de backend/supabase/schema.sql

-- 2
-- contenido de backend/supabase/functions.sql

-- 3
-- contenido de backend/supabase/policies.sql

-- 4
-- contenido de backend/supabase/views.sql

-- 5
-- contenido de backend/supabase/seeds/demo_data.sql
```

Si hace falta depurar paso por paso, tambien se pueden ejecutar con Docker Compose de forma individual:

```bash
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/schema.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/functions.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/policies.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/views.sql'
docker compose --profile tools run --rm supabase-db-client 'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/seeds/demo_data.sql'
```

## Crear un admin

1. Crear o registrar un usuario con Supabase Auth.
2. Copiar su `id` desde Authentication > Users.
3. Ejecutar:

```sql
insert into public.admin_users (user_id)
values ('00000000-0000-0000-0000-000000000000')
on conflict (user_id) do nothing;
```

Reemplazar el UUID por el `id` real del usuario. No guardar credenciales en el repositorio.

## Variables para el frontend

El frontend solo necesita variables publicas:

```bash
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

No usar `SUPABASE_SERVICE_ROLE_KEY` en el frontend.

## Prueba manual con datos demo

1. Ejecutar todos los scripts SQL en el orden documentado.
2. Crear dos usuarios desde la app o desde Supabase Auth.
3. Confirmar que cada usuario tenga fila en `profiles`.
4. Iniciar sesion como usuario normal y crear una prediccion para un partido futuro.
5. Iniciar sesion como admin o usar SQL Editor con un admin en `admin_users`.
6. Cargar resultado con RPC:

```sql
select public.set_match_result(
  '11111111-1111-4111-8111-111111111111',
  2,
  1,
  'finished'
);
```

7. Consultar:

```sql
select * from public.ranking_general;
select * from public.match_cards order by starts_at;
select * from public.my_predictions order by starts_at;
```

Para probar el bloqueo por horario, cambiar temporalmente `starts_at` de un partido a una fecha pasada como admin e intentar editar una prediccion de usuario normal.
