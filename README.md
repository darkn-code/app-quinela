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
- Deploy: imagen Docker de frontend estatico con Nginx para VPS o hosting compatible; Supabase como servicio externo.

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
│   ├── nginx.conf
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── src/
│   ├── README.md
│   └── ...
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

Validar build del frontend dentro de Docker, sin instalar dependencias en el host:

```bash
docker build --target build -t quiniela-mundial-frontend-build ./frontend
```

Construir imagen de produccion para servidor:

```bash
docker compose --profile deploy build frontend-prod
```

Para produccion, definir `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` en `.env` antes de construir. Vite fija esas variables durante el build de la imagen.

Probar imagen de produccion localmente:

```bash
docker compose --profile deploy up frontend-prod
```

La imagen de produccion queda expuesta localmente en:

```text
http://localhost:8080
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

El frontend ya corre como demo React + Vite con datos mock y `localStorage`. El backend Supabase tiene scripts SQL iniciales para esquema, politicas, funciones, vistas y seeds de demo. La conexion real entre frontend y Supabase queda como siguiente etapa.
=======
# app-quinela
