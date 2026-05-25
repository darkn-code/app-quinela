import React from 'react';
import PredictionForm from './PredictionForm.jsx';
import { calculatePredictionPoints } from '../utils/scoring.js';

const dateFormatter = new Intl.DateTimeFormat('es-MX', {
  dateStyle: 'medium',
  timeStyle: 'short',
});

export default function MatchCard({ match, prediction, saving, onSavePrediction }) {
  const locked = !(match.isPredictionOpen ?? new Date(match.startsAt) > new Date());
  const points = prediction?.points ?? calculatePredictionPoints(prediction, match);

  return (
    <article className="match-card">
      <div className="match-meta">
        <span className={locked ? 'status status-locked' : 'status'}>{locked ? 'Bloqueado' : 'Abierto'}</span>
        <span>{dateFormatter.format(new Date(match.startsAt))}</span>
      </div>

      <div className="match-teams">
        <strong>{match.homeTeam}</strong>
        <span>vs</span>
        <strong>{match.awayTeam}</strong>
      </div>

      {match.stadium && <p className="venue">{match.stadium}</p>}

      {match.status === 'finished' && (
        <p className="result-line">
          Resultado: {match.homeScore} - {match.awayScore}
          {prediction ? ` | Tus puntos: ${points}` : ''}
        </p>
      )}

      <PredictionForm
        locked={locked}
        match={match}
        onSave={onSavePrediction}
        prediction={prediction}
        saving={saving}
      />
    </article>
  );
}
