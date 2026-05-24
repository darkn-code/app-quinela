# AGENTS.md

Guia de trabajo para agentes del proyecto `quiniela-mundial`.

## Objetivo comun

Construir una demo web mobile-first de una quiniela del Mundial usando React + Vite en el frontend y Supabase como backend inicial. La prioridad es entregar una demo funcional, simple y facil de desplegar.

## Reglas generales

- No sobreingenierizar.
- No agregar funcionalidades fuera del alcance aprobado.
- No usar secretos reales en el repositorio.
- Mantener cambios pequenos, claros y faciles de revisar.
- Documentar decisiones tecnicas relevantes en `docs/`.
- Evitar dependencias innecesarias.
- Mantener compatibilidad con Docker Compose.
- Antes de modificar archivos compartidos, revisar el estado actual del repositorio.

## Responsabilidades por agente

### Agente frontend

Responsable principal de:

- Carpeta `frontend/`.
- Interfaz React + Vite.
- Estilos mobile-first.
- Integracion con Supabase desde cliente web.
- Experiencia de usuario para login, partidos, predicciones y ranking.
- Documentacion en `docs/frontend.md`.

No debe modificar SQL o politicas de Supabase salvo para proponer cambios documentados.

### Agente backend/Supabase

Responsable principal de:

- Carpeta `backend/`.
- Esquema de Supabase.
- Politicas RLS.
- Vistas SQL.
- Funciones SQL/RPC.
- Seeds de demo.
- Documentacion en `docs/backend_supabase.md`.

No debe modificar componentes o estilos del frontend salvo para ajustar integraciones documentadas.

## Archivos compartidos

Estos archivos pueden ser modificados por ambos agentes cuando sea necesario:

- `README.md`
- `AGENTS.md`
- `.env.example`
- `docker-compose.yml`
- `docs/deployment.md`
- `docs/workflow_git.md`

Cuando se modifiquen archivos compartidos, explicar el motivo en el commit o en la nota de entrega.

## Flujo recomendado

1. Crear una rama por tarea o agente.
2. Mantener cambios acotados al area correspondiente.
3. Validar localmente antes de entregar.
4. Actualizar documentacion si cambia un comando, variable, flujo o contrato.
5. Evitar mezclar refactors con nuevas funcionalidades.

## Criterio de calidad

- La app debe poder levantarse con Docker Compose.
- El frontend debe ser usable en celular.
- Las reglas de negocio deben estar documentadas.
- Supabase debe tener politicas de seguridad revisables.
- El proyecto debe seguir siendo facil de entender para nuevos agentes.
