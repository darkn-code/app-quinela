# Quiniela Mundial

Demo web mobile-first para una quiniela del Mundial. El objetivo es validar rapidamente el flujo principal: usuarios, partidos, predicciones, carga de resultados y ranking basico.

Este repositorio esta preparado para que trabajen dos agentes separados:

- Agente frontend: React + Vite en `frontend/`.
- Agente backend/Supabase: SQL, politicas, vistas, funciones y seeds en `backend/`.

## Stack

- Frontend: React + Vite.
- Estilos: CSS simple mobile-first. Tailwind puede evaluarse si no retrasa la demo.
- Backend inicial: Supabase.
- Base de datos: Supabase PostgreSQL.
- Auth: Supabase Auth o acceso simple definido mas adelante.
- Docker: Docker Compose para desarrollo local.
- Deploy: frontend estatico en hosting web, VPS, Vercel, Netlify o Cloudflare Pages; Supabase como servicio externo.

## Estructura de carpetas

```text
quiniela-mundial/
├── AGENTS.md
├── README.md
├── PLAN_PROYECTO.md
├── docker-compose.yml
├── .env.example
├── .gitignore
├── frontend/
│   ├── Dockerfile
│   ├── README.md
│   └── .gitkeep
├── backend/
│   ├── README.md
│   ├── supabase/
│   │   ├── schema.sql
│   │   ├── policies.sql
│   │   ├── views.sql
│   │   ├── functions.sql
│   │   └── seeds/
│   │       └── demo_data.sql
│   └── .gitkeep
└── docs/
    ├── frontend.md
    ├── backend_supabase.md
    ├── deployment.md
    └── workflow_git.md
```

## Comandos basicos

Copiar variables de entorno:

```bash
cp .env.example .env
```

Validar configuracion de Docker Compose:

```bash
docker compose config
```

Levantar el contenedor del frontend:

```bash
docker compose up --build
```

Cuando el frontend React + Vite este inicializado, la app quedara disponible en:

```text
http://localhost:5173
```

Detener contenedores:

```bash
docker compose down
```

## Flujo recomendado de trabajo

1. Revisar `PLAN_PROYECTO.md`.
2. Crear una rama por tarea.
3. El agente frontend trabaja principalmente en `frontend/`.
4. El agente backend/Supabase trabaja principalmente en `backend/`.
5. Mantener `docker-compose.yml` compatible con ambos flujos.
6. Actualizar la documentacion cuando cambien comandos, variables o decisiones.
7. Validar con Docker Compose antes de entregar cambios funcionales.

## Estado actual

Esta estructura solo prepara la base del proyecto. Todavia no hay componentes React, tablas reales ni logica de quiniela implementada.
