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
