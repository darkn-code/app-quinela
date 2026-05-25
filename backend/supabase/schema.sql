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
