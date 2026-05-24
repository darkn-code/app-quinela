# Deployment

Guia inicial de despliegue.

## Objetivo

La demo debe poder desplegarse rapido, con bajo costo y sin backend propio complejo.

## Opcion recomendada para demo

- Frontend: Vercel, Netlify, Cloudflare Pages, hosting web o VPS.
- Backend: Supabase hosted.

## Variables necesarias

Frontend:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Backend/admin:

- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_DB_URL`

Nunca exponer `SUPABASE_SERVICE_ROLE_KEY` en el frontend.

## Docker

Validar configuracion:

```bash
docker compose config
```

Levantar entorno:

```bash
docker compose up --build
```

## Pendiente

- Definir proveedor final de hosting.
- Agregar pasos especificos de build cuando el frontend exista.
- Documentar configuracion de dominio si aplica.
