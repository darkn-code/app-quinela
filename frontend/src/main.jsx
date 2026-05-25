import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './styles.css';

const rootElement = document.getElementById('root');

try {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  );
} catch (error) {
  rootElement.innerHTML = `
    <main class="login-screen">
      <section class="login-panel">
        <p class="eyebrow">Quiniela Mundial</p>
        <h1>No se pudo cargar la app</h1>
        <p class="login-copy">Recarga la pagina. Si el problema sigue, limpia los datos del sitio.</p>
      </section>
    </main>
  `;
  console.error(error);
}
