import React from 'react';

const tabs = [
  { id: 'dashboard', label: 'Inicio' },
  { id: 'matches', label: 'Partidos' },
  { id: 'ranking', label: 'Ranking' },
];

export default function BottomNav({ activeTab, onChange }) {
  return (
    <nav className="bottom-nav" aria-label="Navegacion principal">
      {tabs.map((tab) => (
        <button
          className={activeTab === tab.id ? 'nav-item nav-item-active' : 'nav-item'}
          key={tab.id}
          type="button"
          onClick={() => onChange(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </nav>
  );
}
