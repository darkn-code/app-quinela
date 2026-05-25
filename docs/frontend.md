# Frontend

Documento de referencia para el agente frontend.

## Objetivo

Crear una app React + Vite mobile-first para la quiniela del Mundial.

## Estado actual

La primera version funcional del frontend ya esta inicializada en `frontend/`.

Incluye:

- Acceso simple por nombre visible, guardado temporalmente en `localStorage`, cuando no hay variables Supabase.
- Supabase Auth con email/password cuando existen `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
- Dashboard con resumen de puntos, predicciones y partidos abiertos.
- Lista de partidos con datos mock o vista `match_cards`.
- Formulario de prediccion de marcador por partido, con upsert autenticado en `predictions`.
- Bloqueo visual y funcional cuando el partido ya inicio.
- Ranking demo que combina usuarios mock con el usuario actual en modo mock.
- Ranking real desde `ranking_general` en modo Supabase.
- Cliente Supabase centralizado en `src/lib/supabase.js` y mapeo de datos en `src/lib/quinielaApi.js`.

La app mantiene fallback a mocks si no hay variables `VITE_` de Supabase.

## Vistas previstas

- Inicio / dashboard.
- Acceso simple.
- Lista de partidos.
- Captura de predicciones.
- Ranking general.
- Administracion simple para resultados, fuera del alcance de esta primera tarea.

## Lineamientos

- Priorizar celular.
- Usar CSS simple antes de introducir librerias.
- Mantener componentes pequenos y legibles.
- Centralizar cliente Supabase y manejo de sesion.
- No implementar reglas de seguridad solo en frontend.

## Estructura

```text
frontend/
├── index.html
├── package.json
├── vite.config.js
└── src/
    ├── App.jsx
    ├── main.jsx
    ├── styles.css
    ├── components/
    ├── data/
    ├── lib/
    └── utils/
```

## Variables de entorno

Vite expone al cliente solo variables con prefijo `VITE_`.

```bash
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

No se deben usar claves privadas o `service_role` dentro del frontend.

Con estas variables configuradas, el frontend espera que el backend tenga aplicados `profiles`, `predictions`, las vistas `match_cards`, `my_predictions`, `ranking_general` y las politicas RLS documentadas por el agente backend.

En desarrollo, Docker Compose pasa estas variables al servidor Vite desde `.env`. En produccion, Vite las fija durante `npm run build`, por eso se pasan como build args y se debe reconstruir la imagen si cambian.

## Comandos con Docker

Desde la raiz del repositorio:

```bash
docker compose up --build
```

La app queda disponible en:

```text
http://localhost:5173
```

Para construir la imagen e instalar dependencias sin tocar el host:

```bash
docker compose build frontend
```

Para validar el build de Vite dentro del contenedor:

```bash
docker compose run --rm frontend npm run build
```

El `Dockerfile` instala dependencias con `npm ci` durante el build de la imagen. No se requiere `npm install` ni `npm ci` en el host.

El frontend no debe depender de un volumen persistente para `/app/node_modules`; debe usar el `node_modules` instalado en la imagen. Si cambian dependencias, reconstruir con `docker compose build frontend`.

## Pendiente

- Agregar vista administrativa solo cuando el alcance lo apruebe.
- Mejorar mensajes de recuperacion de password o magic link si se aprueba para la demo.
