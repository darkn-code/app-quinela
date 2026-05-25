import { supabase } from './supabase.js';

const mapMatch = (row) => ({
  id: row.id,
  homeTeam: row.home_team,
  awayTeam: row.away_team,
  startsAt: row.starts_at,
  stadium: row.stadium || 'Sede por confirmar',
  status: row.status,
  homeScore: row.home_score,
  awayScore: row.away_score,
  isPredictionOpen: row.is_prediction_open,
});

const mapPrediction = (row) => ({
  id: row.id,
  matchId: row.match_id,
  homeScore: row.predicted_home_score,
  awayScore: row.predicted_away_score,
  points: row.points,
  isEditable: row.is_editable,
});

const mapRankingPlayer = (row) => ({
  id: row.user_id,
  name: row.display_name,
  points: row.total_points,
  exactScores: row.exact_scores,
  correctResults: row.correct_results,
  predictions: row.predictions_count,
});

export const getCurrentSession = async () => {
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  return data.session;
};

export const subscribeToAuthChanges = (onChange) =>
  supabase.auth.onAuthStateChange((_event, session) => {
    onChange(session);
  });

export const signInWithPassword = async ({ email, password }) => {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data.session;
};

export const signUpWithPassword = async ({ email, password, displayName }) => {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        display_name: displayName,
      },
    },
  });

  if (error) throw error;
  return data.session;
};

export const signOut = async () => {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
};

export const fetchProfile = async (userId) => {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, display_name')
    .eq('id', userId)
    .maybeSingle();

  if (error) throw error;

  return {
    id: userId,
    name: data?.display_name || 'Jugador',
  };
};

export const fetchQuinielaData = async () => {
  const [matchesResult, predictionsResult, rankingResult] = await Promise.all([
    supabase.from('match_cards').select('*').order('starts_at', { ascending: true }),
    supabase.from('my_predictions').select('*').order('starts_at', { ascending: true }),
    supabase.from('ranking_general').select('*').order('rank_position', { ascending: true }),
  ]);

  const error = matchesResult.error || predictionsResult.error || rankingResult.error;
  if (error) throw error;

  const predictions = {};
  predictionsResult.data.map(mapPrediction).forEach((prediction) => {
    predictions[prediction.matchId] = prediction;
  });

  return {
    matches: matchesResult.data.map(mapMatch),
    predictions,
    ranking: rankingResult.data.map(mapRankingPlayer),
  };
};

export const upsertPrediction = async ({ matchId, prediction }) => {
  const { error } = await supabase.from('predictions').upsert(
    {
      match_id: matchId,
      predicted_home_score: prediction.homeScore,
      predicted_away_score: prediction.awayScore,
    },
    {
      onConflict: 'user_id,match_id',
    },
  );

  if (error) throw error;
};
