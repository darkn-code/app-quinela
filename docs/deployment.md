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

Construir imagen de produccion del frontend:

```bash
docker compose --profile deploy build frontend-prod
```

Las variables `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` se leen desde `.env` durante el build de Vite. Si cambian para produccion, reconstruir la imagen.

Probar la imagen de produccion localmente:

```bash
docker compose --profile deploy up frontend-prod
```

La version de produccion queda disponible localmente en:

```text
http://localhost:8080
```

La imagen `frontend-prod` compila React + Vite y sirve archivos estaticos con Nginx. Supabase se mantiene como servicio externo.

## Pendiente

- Definir proveedor final de hosting.
- Documentar configuracion de dominio si aplica.
