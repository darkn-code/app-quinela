# Workflow Git

Guia simple para trabajar por ramas y agentes.

## Ramas sugeridas

- `main`: version estable o entregable.
- `frontend/*`: tareas del agente frontend.
- `backend/*`: tareas del agente backend/Supabase.
- `docs/*`: cambios de documentacion.

## Flujo recomendado

1. Crear rama desde `main`.
2. Hacer cambios pequenos y enfocados.
3. Validar comandos locales relevantes.
4. Actualizar documentacion si cambia el flujo.
5. Abrir pull request o entregar resumen de cambios.
6. Integrar despues de revision.

## Convencion de commits sugerida

- `docs: actualizar plan de proyecto`
- `chore: preparar docker compose`
- `feat(frontend): agregar vista de partidos`
- `feat(backend): agregar esquema inicial`
- `fix: corregir validacion de predicciones`

## Archivos compartidos

Modificar con cuidado:

- `docker-compose.yml`
- `.env.example`
- `README.md`
- `AGENTS.md`

Si un cambio afecta a ambos agentes, documentar el contrato esperado.
