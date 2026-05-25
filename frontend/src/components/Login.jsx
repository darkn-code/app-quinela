import React from 'react';

export default function Login({
  authError,
  authMode,
  initialName,
  isLoading,
  onAuthModeChange,
  onLogin,
  useSupabaseAuth,
}) {
  const handleSubmit = (event) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const displayName = String(formData.get('displayName') || '').trim();
    const email = String(formData.get('email') || '').trim();
    const password = String(formData.get('password') || '');

    if (useSupabaseAuth) {
      onLogin({ displayName, email, password });
      return;
    }

    if (displayName) {
      onLogin({ name: displayName });
    }
  };

  const title = useSupabaseAuth
    ? authMode === 'signup'
      ? 'Crea tu cuenta'
      : 'Entra a la quiniela'
    : 'Quiniela Mundial';

  return (
    <main className="login-screen">
      <section className="login-panel" aria-labelledby="login-title">
        <p className="eyebrow">{useSupabaseAuth ? 'Supabase Auth' : 'Demo mobile'}</p>
        <h1 id="login-title">{title}</h1>
        <p className="login-copy">
          {useSupabaseAuth
            ? 'Usa email y password para guardar tus predicciones en Supabase.'
            : 'Entra con tu nombre para probar el flujo de partidos, predicciones y ranking.'}
        </p>

        <form className="login-form" onSubmit={handleSubmit}>
          {useSupabaseAuth && (
            <div className="auth-toggle" role="group" aria-label="Modo de acceso">
              <button
                className={authMode === 'signin' ? 'toggle-button toggle-button-active' : 'toggle-button'}
                type="button"
                onClick={() => onAuthModeChange('signin')}
              >
                Entrar
              </button>
              <button
                className={authMode === 'signup' ? 'toggle-button toggle-button-active' : 'toggle-button'}
                type="button"
                onClick={() => onAuthModeChange('signup')}
              >
                Crear
              </button>
            </div>
          )}

          {(!useSupabaseAuth || authMode === 'signup') && (
            <>
              <label htmlFor="displayName">Nombre visible</label>
              <input
                autoComplete="name"
                defaultValue={initialName}
                id="displayName"
                name="displayName"
                placeholder="Ej. Carlos"
                required
                type="text"
              />
            </>
          )}

          {useSupabaseAuth && (
            <>
              <label htmlFor="email">Email</label>
              <input
                autoComplete="email"
                id="email"
                name="email"
                placeholder="tu@email.com"
                required
                type="email"
              />

              <label htmlFor="password">Password</label>
              <input
                autoComplete={authMode === 'signup' ? 'new-password' : 'current-password'}
                id="password"
                minLength="6"
                name="password"
                required
                type="password"
              />
            </>
          )}

          {authError && <p className="form-error">{authError}</p>}

          <button className="primary-button" disabled={isLoading} type="submit">
            {isLoading ? 'Procesando...' : 'Entrar a la quiniela'}
          </button>
        </form>
      </section>
    </main>
  );
}
