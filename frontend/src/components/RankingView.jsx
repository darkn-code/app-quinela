import React from 'react';

export default function RankingView({ ranking }) {
  return (
    <section className="screen-section" aria-labelledby="ranking-title">
      <div className="section-heading">
        <p className="eyebrow">Tabla general</p>
        <h1 id="ranking-title">Ranking</h1>
      </div>

      <div className="ranking-list">
        {ranking.map((player, index) => (
          <article className="ranking-row" key={player.id}>
            <span className="rank-position">{player.rankPosition ?? index + 1}</span>
            <div>
              <strong>{player.name}</strong>
              <p>
                {player.exactScores} exactos | {player.predictions} predicciones
              </p>
            </div>
            <span className="rank-points">{player.points}</span>
          </article>
        ))}
      </div>
    </section>
  );
}
