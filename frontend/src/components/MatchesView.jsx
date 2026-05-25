import React from 'react';
import MatchCard from './MatchCard.jsx';

export default function MatchesView({ error, matches, onRefresh, predictions, savingMatchId, onSavePrediction }) {
  return (
    <section className="screen-section" aria-labelledby="matches-title">
      <div className="section-heading">
        <p className="eyebrow">Jornada demo</p>
        <h1 id="matches-title">Partidos</h1>
      </div>

      {error && (
        <div className="notice-card">
          <p>{error}</p>
          <button className="secondary-button" type="button" onClick={onRefresh}>
            Reintentar
          </button>
        </div>
      )}

      <div className="match-list">
        {matches.map((match) => (
          <MatchCard
            key={match.id}
            match={match}
            onSavePrediction={onSavePrediction}
            prediction={predictions[match.id]}
            saving={savingMatchId === match.id}
          />
        ))}
      </div>
    </section>
  );
}
