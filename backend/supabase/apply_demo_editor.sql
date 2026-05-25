-- ============================================================
-- backend/supabase/schema.sql
-- ============================================================

-- schema.sql
-- Esquema inicial de Supabase para la demo de quiniela.
-- Ejecutar primero. Luego ejecutar functions.sql, policies.sql, views.sql y seeds/demo_data.sql.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Jugador',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_not_blank check (length(trim(display_name)) > 0)
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  home_team text not null,
  away_team text not null,
  starts_at timestamptz not null,
  status text not null default 'scheduled',
  home_score integer,
  away_score integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint matches_home_team_not_blank check (length(trim(home_team)) > 0),
  constraint matches_away_team_not_blank check (length(trim(away_team)) > 0),
  constraint matches_different_teams check (lower(trim(home_team)) <> lower(trim(away_team))),
  constraint matches_valid_status check (status in ('scheduled', 'live', 'finished')),
  constraint matches_scores_together check (
    (home_score is null and away_score is null)
    or (home_score is not null and away_score is not null)
  ),
  constraint matches_non_negative_scores check (
    (home_score is null or home_score >= 0)
    and (away_score is null or away_score >= 0)
  ),
  constraint matches_finished_requires_scores check (
    status <> 'finished'
    or (home_score is not null and away_score is not null)
  )
);

create table if not exists public.predictions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  match_id uuid not null references public.matches(id) on delete cascade,
  predicted_home_score integer not null,
  predicted_away_score integer not null,
  points integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint predictions_one_per_user_match unique (user_id, match_id),
  constraint predictions_non_negative_scores check (
    predicted_home_score >= 0
    and predicted_away_score >= 0
  ),
  constraint predictions_valid_points check (points in (0, 3, 5))
);

create index if not exists matches_starts_at_idx on public.matches(starts_at);
create index if not exists matches_status_idx on public.matches(status);
create index if not exists predictions_user_id_idx on public.predictions(user_id);
create index if not exists predictions_match_id_idx on public.predictions(match_id);

alter table public.predictions
  alter column user_id set default auth.uid();



-- ============================================================
-- backend/supabase/functions.sql
-- ============================================================

-- functions.sql
-- Funciones, RPC y triggers para reglas de negocio.
-- Ejecutar despues de schema.sql y antes de policies.sql.

create or replace function public.is_admin(user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users admins
    where admins.user_id = is_admin.user_id
  );
$$;

create or replace function public.can_predict_match(match_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.matches matches
    where matches.id = can_predict_match.match_id
      and matches.starts_at > now()
      and matches.status = 'scheduled'
  );
$$;

create or replace function public.calculate_prediction_points(
  predicted_home_score integer,
  predicted_away_score integer,
  actual_home_score integer,
  actual_away_score integer
)
returns integer
language sql
immutable
as $$
  select case
    when actual_home_score is null or actual_away_score is null then 0
    when predicted_home_score = actual_home_score
      and predicted_away_score = actual_away_score then 5
    when sign(predicted_home_score - predicted_away_score)
      = sign(actual_home_score - actual_away_score) then 3
    else 0
  end;
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      split_part(new.email, '@', 1),
      'Jugador'
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user_profile();

create or replace function public.prepare_prediction_write()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  match_record public.matches%rowtype;
  should_check_deadline boolean;
begin
  select *
  into match_record
  from public.matches
  where id = new.match_id;

  if not found then
    raise exception 'Match does not exist';
  end if;

  if tg_op = 'INSERT' then
    should_check_deadline := true;
  else
    should_check_deadline := new.match_id is distinct from old.match_id
      or new.predicted_home_score is distinct from old.predicted_home_score
      or new.predicted_away_score is distinct from old.predicted_away_score;
  end if;

  if should_check_deadline
    and (match_record.starts_at <= now() or match_record.status <> 'scheduled') then
    raise exception 'Predictions cannot be changed after match start';
  end if;

  new.points = public.calculate_prediction_points(
    new.predicted_home_score,
    new.predicted_away_score,
    match_record.home_score,
    match_record.away_score
  );

  return new;
end;
$$;

drop trigger if exists prepare_prediction_write on public.predictions;
create trigger prepare_prediction_write
  before insert or update on public.predictions
  for each row execute function public.prepare_prediction_write();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists set_matches_updated_at on public.matches;
create trigger set_matches_updated_at
  before update on public.matches
  for each row execute function public.set_updated_at();

drop trigger if exists set_predictions_updated_at on public.predictions;
create trigger set_predictions_updated_at
  before update on public.predictions
  for each row execute function public.set_updated_at();

create or replace function public.recalculate_match_predictions(match_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_rows integer;
begin
  update public.predictions predictions
  set points = public.calculate_prediction_points(
      predictions.predicted_home_score,
      predictions.predicted_away_score,
      matches.home_score,
      matches.away_score
    ),
    updated_at = now()
  from public.matches matches
  where predictions.match_id = matches.id
    and matches.id = recalculate_match_predictions.match_id;

  get diagnostics updated_rows = row_count;
  return updated_rows;
end;
$$;

create or replace function public.recalculate_predictions_after_result()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.home_score is distinct from old.home_score
    or new.away_score is distinct from old.away_score
    or new.status is distinct from old.status then
    perform public.recalculate_match_predictions(new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists recalculate_predictions_after_result on public.matches;
create trigger recalculate_predictions_after_result
  after update of home_score, away_score, status on public.matches
  for each row execute function public.recalculate_predictions_after_result();

create or replace function public.set_match_result(
  match_id uuid,
  home_score integer,
  away_score integer,
  status text default 'finished'
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin(auth.uid()) then
    raise exception 'Only admins can update match results';
  end if;

  if home_score < 0 or away_score < 0 then
    raise exception 'Scores must be zero or greater';
  end if;

  update public.matches
  set home_score = set_match_result.home_score,
    away_score = set_match_result.away_score,
    status = set_match_result.status
  where id = set_match_result.match_id;

  if not found then
    raise exception 'Match does not exist';
  end if;

  return public.recalculate_match_predictions(match_id);
end;
$$;

revoke execute on function public.recalculate_match_predictions(uuid) from public;
revoke execute on function public.recalculate_match_predictions(uuid) from anon;
revoke execute on function public.recalculate_match_predictions(uuid) from authenticated;

grant execute on function public.is_admin(uuid) to authenticated;
grant execute on function public.can_predict_match(uuid) to authenticated;
grant execute on function public.calculate_prediction_points(integer, integer, integer, integer) to authenticated;
grant execute on function public.set_match_result(uuid, integer, integer, text) to authenticated;



-- ============================================================
-- backend/supabase/policies.sql
-- ============================================================

-- policies.sql
-- Politicas Row Level Security para Supabase.
-- Ejecutar despues de functions.sql.

alter table public.profiles enable row level security;
alter table public.admin_users enable row level security;
alter table public.matches enable row level security;
alter table public.predictions enable row level security;

grant usage on schema public to authenticated;

grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;

grant select on public.admin_users to authenticated;

grant select on public.matches to authenticated;

grant select, insert, update, delete on public.predictions to authenticated;

drop policy if exists "profiles are readable by authenticated users" on public.profiles;
create policy "profiles are readable by authenticated users"
  on public.profiles
  for select
  to authenticated
  using (true);

drop policy if exists "users can update own profile" on public.profiles;
create policy "users can update own profile"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "admins can read admin users" on public.admin_users;
create policy "admins can read admin users"
  on public.admin_users
  for select
  to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists "matches are readable by authenticated users" on public.matches;
create policy "matches are readable by authenticated users"
  on public.matches
  for select
  to authenticated
  using (true);

drop policy if exists "admins can insert matches" on public.matches;
create policy "admins can insert matches"
  on public.matches
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists "admins can update matches and results" on public.matches;
create policy "admins can update matches and results"
  on public.matches
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "users can read own predictions" on public.predictions;
create policy "users can read own predictions"
  on public.predictions
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "users can insert own predictions before match start" on public.predictions;
create policy "users can insert own predictions before match start"
  on public.predictions
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.can_predict_match(match_id)
  );

drop policy if exists "users can update own predictions before match start" on public.predictions;
create policy "users can update own predictions before match start"
  on public.predictions
  for update
  to authenticated
  using (
    user_id = auth.uid()
    and public.can_predict_match(match_id)
  )
  with check (
    user_id = auth.uid()
    and public.can_predict_match(match_id)
  );

drop policy if exists "users can delete own predictions before match start" on public.predictions;
create policy "users can delete own predictions before match start"
  on public.predictions
  for delete
  to authenticated
  using (
    user_id = auth.uid()
    and public.can_predict_match(match_id)
  );



-- ============================================================
-- backend/supabase/views.sql
-- ============================================================

-- views.sql
-- Vistas de lectura para la demo.
-- Ejecutar despues de policies.sql.

create or replace view public.ranking_general as
select
  row_number() over (
    order by
      coalesce(sum(predictions.points), 0) desc,
      count(predictions.id) filter (where predictions.points = 5) desc,
      profiles.display_name asc
  ) as rank_position,
  profiles.id as user_id,
  profiles.display_name,
  coalesce(sum(predictions.points), 0)::integer as total_points,
  count(predictions.id) filter (where predictions.points = 5)::integer as exact_scores,
  count(predictions.id) filter (where predictions.points = 3)::integer as correct_results,
  count(predictions.id)::integer as predictions_count
from public.profiles
left join public.predictions on predictions.user_id = profiles.id
group by profiles.id, profiles.display_name;

create or replace view public.match_cards
with (security_invoker = true) as
select
  matches.id,
  matches.home_team,
  matches.away_team,
  matches.starts_at,
  matches.status,
  matches.home_score,
  matches.away_score,
  matches.starts_at > now()
    and matches.status = 'scheduled' as is_prediction_open
from public.matches;

create or replace view public.my_predictions
with (security_invoker = true) as
select
  predictions.id,
  predictions.user_id,
  predictions.match_id,
  matches.home_team,
  matches.away_team,
  matches.starts_at,
  matches.status,
  matches.home_score,
  matches.away_score,
  predictions.predicted_home_score,
  predictions.predicted_away_score,
  predictions.points,
  predictions.created_at,
  predictions.updated_at,
  matches.starts_at > now()
    and matches.status = 'scheduled' as is_editable
from public.predictions
join public.matches on matches.id = predictions.match_id;

grant select on public.ranking_general to authenticated;
grant select on public.match_cards to authenticated;
grant select on public.my_predictions to authenticated;



-- ============================================================
-- backend/supabase/seeds/demo_data.sql
-- ============================================================

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



