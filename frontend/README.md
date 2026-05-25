# Frontend

App React + Vite mobile-first para la quiniela del Mundial.

## Responsabilidad

- Crear la interfaz mobile-first.
- Consumir Supabase desde el cliente.
- Implementar vistas de inicio, auth, partidos, predicciones, ranking y administracion simple cuando el plan sea aprobado para desarrollo.
- Mantener estilos simples y faciles de mantener.

## Stack previsto

- React.
- Vite.
- CSS mobile-first.
- Supabase JS client.

## Comandos con Docker

Desde la raiz del repositorio:

```bash
docker compose up --build
```

Build de verificacion sin instalar dependencias en la PC:

```bash
docker build --target build -t quiniela-mundial-frontend-build ./frontend
```

Imagen de produccion para servidor:

```bash
docker compose --profile deploy build frontend-prod
```

Las variables `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` deben estar en `.env` antes de construir la imagen de produccion.

El `Dockerfile` instala dependencias con `npm ci` durante el build de la imagen. No se requiere instalar paquetes en el host.

El contenedor de desarrollo usa el `node_modules` de la imagen. Si cambian `package.json` o `package-lock.json`, reconstruir la imagen con `docker compose build frontend`.

## Estado actual

La app funciona en dos modos:

- Sin variables `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`: modo demo con datos mock y `localStorage`.
- Con variables Supabase: usa Supabase Auth con email/password, lee `match_cards`, `my_predictions` y `ranking_general`, y guarda predicciones en `predictions`.

Vistas incluidas:

- Acceso simple por nombre en modo mock.
- Auth email/password en modo Supabase.
- Dashboard.
- Partidos desde mock o vista `match_cards`.
- Formulario de prediccion con upsert autenticado en `predictions`.
- Ranking desde mock o vista `ranking_general`.

Supabase queda preparado en `src/lib/supabase.js` usando:

```bash
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
```

No se deben exponer claves privadas ni `service_role` en variables `VITE_`.
