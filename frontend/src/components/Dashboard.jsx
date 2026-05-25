import React from 'react';

export default function Dashboard({ user, matches, predictions, totalPoints, onGoToMatches }) {
  const openMatches = matches.filter((match) =>
    match.isPredictionOpen ?? new Date(match.startsAt) > new Date(),
  ).length;
  const predictionCount = Object.keys(predictions).length;

  return (
    <section className="screen-section" aria-labelledby="dashboard-title">
      <div className="hero-panel">
        <p className="eyebrow">Bienvenido</p>
        <h1 id="dashboard-title">{user.name}</h1>
        <p>Haz tus marcadores antes de que inicie cada partido.</p>
        <button className="primary-button" type="button" onClick={onGoToMatches}>
          Capturar predicciones
        </button>
      </div>

      <div className="stats-grid" aria-label="Resumen de quiniela">
        <article className="stat-card">
          <span>{totalPoints}</span>
          <p>Puntos</p>
        </article>
        <article className="stat-card">
          <span>{predictionCount}</span>
          <p>Predicciones</p>
        </article>
        <article className="stat-card">
          <span>{openMatches}</span>
          <p>Abiertos</p>
        </article>
      </div>

      <article className="info-card">
        <h2>Reglas de puntos</h2>
        <p>Marcador exacto suma 5 puntos. Resultado correcto suma 3 puntos. Sin acierto suma 0.</p>
      </article>
    </section>
  );
}
