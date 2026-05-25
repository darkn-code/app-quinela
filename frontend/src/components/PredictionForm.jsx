import React, { useEffect, useState } from 'react';

export default function PredictionForm({ match, prediction, locked, onSave, saving }) {
  const [homeScore, setHomeScore] = useState(prediction?.homeScore ?? '');
  const [awayScore, setAwayScore] = useState(prediction?.awayScore ?? '');

  useEffect(() => {
    setHomeScore(prediction?.homeScore ?? '');
    setAwayScore(prediction?.awayScore ?? '');
  }, [prediction?.awayScore, prediction?.homeScore]);

  const handleSubmit = (event) => {
    event.preventDefault();

    onSave(match.id, {
      homeScore: Number(homeScore),
      awayScore: Number(awayScore),
    });
  };

  return (
    <form className="prediction-form" onSubmit={handleSubmit}>
      <label>
        {match.homeTeam}
        <input
          disabled={locked || saving}
          min="0"
          name="homeScore"
          onChange={(event) => setHomeScore(event.target.value)}
          required
          type="number"
          value={homeScore}
        />
      </label>
      <span className="score-separator">-</span>
      <label>
        {match.awayTeam}
        <input
          disabled={locked || saving}
          min="0"
          name="awayScore"
          onChange={(event) => setAwayScore(event.target.value)}
          required
          type="number"
          value={awayScore}
        />
      </label>
      <button className="secondary-button" disabled={locked || saving} type="submit">
        {saving ? 'Guardando...' : 'Guardar'}
      </button>
    </form>
  );
}
