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
