# Backend / Supabase

Documento de referencia para el agente backend/Supabase.

## Objetivo

Configurar Supabase como backend principal de la demo, evitando un backend propio mientras sea posible.

## Archivos principales

- `backend/supabase/schema.sql`: tablas y restricciones.
- `backend/supabase/policies.sql`: politicas RLS.
- `backend/supabase/views.sql`: vistas para ranking y consultas agregadas.
- `backend/supabase/functions.sql`: funciones SQL/RPC.
- `backend/supabase/seeds/demo_data.sql`: datos de prueba.

## Criterios

- Mantener el modelo de datos simple.
- Proteger predicciones por usuario.
- Separar permisos de usuario normal y administrador.
- Usar timestamps con zona horaria.
- Evitar datos duplicados con restricciones SQL.

## Pendiente

- Definir tablas reales.
- Definir politicas RLS.
- Crear seed de partidos.
- Definir si el calculo de puntos se ejecuta con funcion SQL, vista o proceso manual para demo.
