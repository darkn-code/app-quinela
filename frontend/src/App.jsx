import React, { useCallback, useEffect, useMemo, useState } from 'react';
import BottomNav from './components/BottomNav.jsx';
import Dashboard from './components/Dashboard.jsx';
import Login from './components/Login.jsx';
import MatchesView from './components/MatchesView.jsx';
import RankingView from './components/RankingView.jsx';
import { mockMatches, mockRanking } from './data/mockData.js';
import {
  fetchProfile,
  fetchQuinielaData,
  getCurrentSession,
  signInWithPassword,
  signOut,
  signUpWithPassword,
  subscribeToAuthChanges,
  upsertPrediction,
} from './lib/quinielaApi.js';
import { isSupabaseConfigured } from './lib/supabase.js';
import { calculatePredictionPoints } from './utils/scoring.js';

const readStoredJson = (key, fallbackValue) => {
  try {
    const rawValue = window.localStorage.getItem(key);
    return rawValue ? JSON.parse(rawValue) : fallbackValue;
  } catch {
    window.localStorage.removeItem(key);
    return fallbackValue;
  }
};

const storedUser = () => {
  return readStoredJson('quiniela_user', null);
};

const storedPredictions = () => {
  return readStoredJson('quiniela_predictions', {});
};

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [authError, setAuthError] = useState('');
  const [authMode, setAuthMode] = useState('signin');
  const [isAuthLoading, setIsAuthLoading] = useState(isSupabaseConfigured);
  const [isDataLoading, setIsDataLoading] = useState(false);
  const [dataError, setDataError] = useState('');
  const [session, setSession] = useState(null);
  const [savingMatchId, setSavingMatchId] = useState(null);
  const [user, setUser] = useState(isSupabaseConfigured ? null : storedUser);
  const [matches, setMatches] = useState(mockMatches);
  const [predictions, setPredictions] = useState(storedPredictions);
  const [rankingFromSupabase, setRankingFromSupabase] = useState([]);

  const loadSupabaseData = useCallback(async () => {
    if (!isSupabaseConfigured) return;

    setIsDataLoading(true);
    setDataError('');

    try {
      const data = await fetchQuinielaData();
      setMatches(data.matches);
      setPredictions(data.predictions);
      setRankingFromSupabase(data.ranking);
    } catch (error) {
      setDataError(error.message || 'No se pudieron cargar los datos de Supabase.');
    } finally {
      setIsDataLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!isSupabaseConfigured) return undefined;

    let isMounted = true;

    const applySession = async (nextSession) => {
      if (!isMounted) return;
      setSession(nextSession);
      setAuthError('');

      if (!nextSession?.user) {
        setUser(null);
        setMatches(mockMatches);
        setPredictions({});
        setRankingFromSupabase([]);
        setIsAuthLoading(false);
        return;
      }

      try {
        const profile = await fetchProfile(nextSession.user.id);
        if (!isMounted) return;
        setUser(profile);
        setIsAuthLoading(false);
        await loadSupabaseData();
      } catch (error) {
        if (!isMounted) return;
        setAuthError(error.message || 'No se pudo cargar el perfil.');
        setIsAuthLoading(false);
      }
    };

    getCurrentSession()
      .then(applySession)
      .catch((error) => {
        if (!isMounted) return;
        setAuthError(error.message || 'No se pudo revisar la sesion.');
        setIsAuthLoading(false);
      });

    const {
      data: { subscription },
    } = subscribeToAuthChanges(applySession);

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, [loadSupabaseData]);

  const totalPoints = useMemo(
    () =>
      matches.reduce(
        (total, match) =>
          total +
          (typeof predictions[match.id]?.points === 'number'
            ? predictions[match.id].points
            : calculatePredictionPoints(predictions[match.id], match)),
        0,
      ),
    [matches, predictions],
  );

  const ranking = useMemo(() => {
    if (isSupabaseConfigured) return rankingFromSupabase;
    if (!user) return mockRanking;

    const currentUser = {
      id: 'current-user',
      name: user.name,
      points: totalPoints,
      exactScores: matches.filter(
        (match) => calculatePredictionPoints(predictions[match.id], match) === 5,
      ).length,
      predictions: Object.keys(predictions).length,
    };

    return [...mockRanking, currentUser].sort((a, b) => b.points - a.points);
  }, [matches, predictions, rankingFromSupabase, totalPoints, user]);

  const handleLogin = async (credentials) => {
    setAuthError('');

    if (!isSupabaseConfigured) {
      window.localStorage.setItem('quiniela_user', JSON.stringify(credentials));
      setUser(credentials);
      return;
    }

    setIsAuthLoading(true);

    try {
      const nextSession =
        authMode === 'signup'
          ? await signUpWithPassword(credentials)
          : await signInWithPassword(credentials);

      if (!nextSession) {
        setAuthError('Revisa tu correo para confirmar la cuenta antes de iniciar sesion.');
      }
    } catch (error) {
      setAuthError(error.message || 'No se pudo iniciar sesion.');
    } finally {
      setIsAuthLoading(false);
    }
  };

  const handleLogout = async () => {
    setDataError('');

    if (!isSupabaseConfigured) {
      window.localStorage.removeItem('quiniela_user');
      setUser(null);
      setActiveTab('dashboard');
      return;
    }

    try {
      await signOut();
      setActiveTab('dashboard');
    } catch (error) {
      setDataError(error.message || 'No se pudo cerrar sesion.');
    }
  };

  const handleSavePrediction = async (matchId, prediction) => {
    const nextPredictions = {
      ...predictions,
      [matchId]: prediction,
    };

    setPredictions(nextPredictions);

    if (!isSupabaseConfigured) {
      window.localStorage.setItem('quiniela_predictions', JSON.stringify(nextPredictions));
      return;
    }

    setDataError('');
    setSavingMatchId(matchId);

    try {
      if (!session?.user?.id) {
        throw new Error('Debes iniciar sesion para guardar predicciones.');
      }

      await upsertPrediction({
        matchId,
        prediction,
      });
      await loadSupabaseData();
    } catch (error) {
      setDataError(error.message || 'No se pudo guardar la prediccion.');
      await loadSupabaseData();
    } finally {
      setSavingMatchId(null);
    }
  };

  if (!user) {
    return (
      <Login
        authError={authError}
        authMode={authMode}
        initialName=""
        isLoading={isAuthLoading}
        onAuthModeChange={setAuthMode}
        onLogin={handleLogin}
        useSupabaseAuth={isSupabaseConfigured}
      />
    );
  }

  return (
    <div className="app-shell">
      <header className="app-header">
        <div>
          <span>Quiniela Mundial</span>
          <small>{isSupabaseConfigured ? 'Conectado a Supabase' : 'Modo demo con mocks'}</small>
        </div>
        <button className="ghost-button" type="button" onClick={handleLogout}>
          Salir
        </button>
      </header>

      <main className="app-main">
        {dataError && <p className="app-alert">{dataError}</p>}
        {isDataLoading && <p className="app-alert">Cargando datos...</p>}

        {activeTab === 'dashboard' && (
          <Dashboard
            matches={matches}
            onGoToMatches={() => setActiveTab('matches')}
            predictions={predictions}
            totalPoints={totalPoints}
            user={user}
          />
        )}
        {activeTab === 'matches' && (
          <MatchesView
            error={dataError}
            matches={matches}
            onRefresh={loadSupabaseData}
            onSavePrediction={handleSavePrediction}
            predictions={predictions}
            savingMatchId={savingMatchId}
          />
        )}
        {activeTab === 'ranking' && <RankingView ranking={ranking} />}
      </main>

      <BottomNav activeTab={activeTab} onChange={setActiveTab} />
    </div>
  );
}
