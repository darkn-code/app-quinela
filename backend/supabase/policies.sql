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
