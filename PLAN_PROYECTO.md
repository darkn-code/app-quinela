# Plan de proyecto: Demo de quiniela del Mundial

## 1. Resumen del proyecto

El proyecto consiste en desarrollar una demo funcional de una quiniela web para el Mundial, enfocada principalmente en uso móvil. La aplicación permitirá que los usuarios ingresen, consulten partidos, registren predicciones de marcador, acumulen puntos según los resultados reales y vean un ranking general.

La prioridad de esta primera versión es demostrar el flujo principal de negocio con el menor alcance posible, usando una arquitectura simple, fácil de desplegar y fácil de continuar después.

## 2. Objetivos principales

- Crear una demo web funcional y presentable para cliente.
- Priorizar una experiencia móvil clara, rápida y responsive.
- Permitir registro o acceso de usuarios.
- Mostrar una lista de partidos disponibles.
- Permitir capturar predicciones de marcador antes del inicio del partido.
- Bloquear la edición de predicciones cuando el partido ya comenzó.
- Permitir cargar resultados reales mediante un mecanismo simple de administración.
- Calcular puntos básicos por predicción.
- Mostrar un ranking general de usuarios.
- Mantener el código organizado y el stack lo más simple posible.

## 3. Alcance de la demo

La primera versión incluirá:

1. Página de inicio con acceso claro a la quiniela.
2. Registro o inicio de sesión de usuario.
3. Vista de partidos.
4. Captura y edición de predicciones de marcador.
5. Validación para impedir cambios después de la hora de inicio del partido.
6. Panel simple o mecanismo controlado para registrar resultados reales.
7. Cálculo básico de puntos.
8. Ranking general por puntaje acumulado.
9. Diseño responsive optimizado para celular.
10. Estructura de base de datos en Supabase.
11. Deploy sencillo en hosting web, VPS o plataforma estática.

## 4. Funcionalidades fuera de alcance

Para mantener la demo rápida y controlada, quedan fuera de la primera versión:

- Pagos o monetización.
- Notificaciones push, correo transaccional avanzado o recordatorios.
- Grupos privados o ligas personalizadas.
- App nativa para iOS o Android.
- Diseño visual avanzado o sistema de diseño completo.
- Integración automática con APIs deportivas.
- Panel administrativo complejo.
- Roles avanzados y permisos granulares.
- Recuperación avanzada de cuenta más allá de lo que provea Supabase Auth.
- Historial detallado de cambios.
- Comentarios, chat o funciones sociales.
- Multiidioma.
- Reglas de desempate complejas.

## 5. Stack tecnológico recomendado

### Frontend

Recomendación inicial: React con Vite.

Motivos:

- Permite avanzar rápido sin cargar un framework grande.
- Facilita manejar estado de sesión, formularios, ranking y vistas.
- Tiene deploy sencillo como sitio estático.
- Deja una base más mantenible si la demo crece.

Alternativa ultra simple: HTML, CSS y JavaScript vanilla.

Esta opción puede funcionar si se busca máxima simplicidad, pero React con Vite probablemente dará mejor estructura sin agregar demasiada complejidad.

### Estilos

- CSS propio con enfoque mobile-first.
- Evitar librerías visuales grandes en la demo inicial.
- Usar componentes simples: botones, inputs, tarjetas de partido, tablas compactas.

### Base de datos y autenticación

- Supabase PostgreSQL.
- Supabase Auth con email/password.
- Row Level Security configurado para proteger predicciones por usuario.

### Backend

- Evitar backend propio en la primera versión.
- Usar Supabase directamente desde el frontend para autenticación, lectura y escritura.
- Si se requiere lógica adicional para recalcular puntos, usar una de estas opciones simples:
  - función SQL en Supabase;
  - RPC de Supabase;
  - script manual temporal para demo;
  - Edge Function solo si la lógica crece.

### Deploy

- Frontend estático en Vercel, Netlify, Cloudflare Pages, hosting web o VPS con Nginx.
- Supabase como servicio externo para base de datos, autenticación y API.

## 6. Arquitectura general

La arquitectura propuesta es:

```text
Usuario móvil / navegador
        |
        v
Frontend web responsive
React + Vite / HTML + CSS + JS
        |
        v
Supabase client
        |
        +--> Supabase Auth
        |
        +--> Supabase PostgreSQL
             - usuarios/perfiles
             - partidos
             - predicciones
             - resultados
             - ranking calculado
```

Principios de arquitectura:

- El frontend consume Supabase directamente.
- La sesión del usuario se maneja con Supabase Auth.
- Las predicciones se guardan en una tabla asociada al usuario autenticado.
- Los partidos y resultados reales viven en Supabase.
- El ranking se puede calcular mediante una vista SQL, una consulta agregada o una tabla materializada simple si después se necesita rendimiento.
- Para la demo, se prioriza claridad sobre optimización prematura.

## 7. Tablas necesarias en Supabase

### `profiles`

Guarda información básica del usuario visible en ranking.

Campos sugeridos:

- `id` UUID, primary key, relacionado con `auth.users.id`.
- `display_name` text, nombre visible del usuario.
- `created_at` timestamp.

### `matches`

Guarda los partidos de la quiniela.

Campos sugeridos:

- `id` UUID, primary key.
- `home_team` text, equipo local.
- `away_team` text, equipo visitante.
- `starts_at` timestamp with time zone, fecha y hora de inicio.
- `home_score` integer, marcador real local, nullable.
- `away_score` integer, marcador real visitante, nullable.
- `status` text, por ejemplo `scheduled`, `live`, `finished`.
- `created_at` timestamp.

Nota: Para la demo, los resultados reales pueden vivir directamente en `matches` para evitar una tabla extra. Si se quiere separar más adelante, se puede crear `match_results`.

### `predictions`

Guarda las predicciones de cada usuario por partido.

Campos sugeridos:

- `id` UUID, primary key.
- `user_id` UUID, relacionado con `auth.users.id`.
- `match_id` UUID, relacionado con `matches.id`.
- `predicted_home_score` integer.
- `predicted_away_score` integer.
- `points` integer, default `0`.
- `created_at` timestamp.
- `updated_at` timestamp.

Restricciones recomendadas:

- Unique compuesto: `user_id`, `match_id`.
- Scores no negativos.
- RLS para que cada usuario solo pueda crear, leer y editar sus propias predicciones.
- Política o validación para evitar edición cuando `matches.starts_at <= now()`.

### `admin_users`

Tabla simple para identificar usuarios con permiso administrativo.

Campos sugeridos:

- `user_id` UUID, primary key, relacionado con `auth.users.id`.
- `created_at` timestamp.

Uso:

- Permitir cargar resultados reales solo a usuarios registrados como administradores.
- Mantenerlo simple para demo.

### Vista opcional `ranking`

Vista SQL para calcular el ranking general.

Campos calculados:

- `user_id`.
- `display_name`.
- `total_points`.
- `exact_scores`.
- `correct_results`.
- `predictions_count`.

La vista puede sumar `predictions.points` y ordenar de mayor a menor.

## 8. Flujo básico del usuario

1. El usuario abre la app desde el celular.
2. Ve la página de inicio.
3. Se registra o inicia sesión.
4. Entra a la lista de partidos.
5. Captura un marcador para cada partido disponible.
6. Guarda sus predicciones.
7. Antes del inicio del partido, puede editar su predicción.
8. Cuando el partido comienza, la predicción queda bloqueada.
9. Después de cargarse el resultado real, la app muestra los puntos obtenidos.
10. El usuario consulta su posición en el ranking general.

## 9. Flujo básico del administrador

1. El administrador inicia sesión.
2. Accede a una vista simple de administración.
3. Consulta los partidos cargados.
4. Registra o edita el resultado real de un partido.
5. Marca el partido como finalizado.
6. El sistema recalcula los puntos de las predicciones relacionadas.
7. El ranking general se actualiza con los nuevos puntajes.

Para la demo, la vista administrativa puede ser sencilla y protegida por una verificación contra `admin_users`.

## 10. Reglas de puntuación

Reglas iniciales:

- Marcador exacto: 5 puntos.
- Resultado correcto: 3 puntos.
- Sin acierto: 0 puntos.

Definiciones:

- Marcador exacto: el usuario predijo correctamente goles de ambos equipos.
- Resultado correcto: el usuario acertó si ganó local, ganó visitante o hubo empate, aunque no haya acertado el marcador exacto.
- Sin acierto: el resultado predicho no coincide con el resultado real.

Ejemplos:

- Real: México 2 - 1 Alemania. Predicción: México 2 - 1 Alemania. Resultado: 5 puntos.
- Real: México 2 - 1 Alemania. Predicción: México 1 - 0 Alemania. Resultado: 3 puntos.
- Real: México 2 - 1 Alemania. Predicción: México 1 - 1 Alemania. Resultado: 0 puntos.
- Real: México 0 - 0 Alemania. Predicción: México 1 - 1 Alemania. Resultado: 3 puntos.

## 11. Plan de desarrollo por etapas

### Etapa 1: Preparación del proyecto

- Elegir stack final entre React + Vite o HTML/CSS/JS.
- Crear estructura base del proyecto.
- Configurar variables de entorno de Supabase.
- Crear proyecto en Supabase.
- Definir esquema SQL inicial.

### Etapa 2: Base de datos y seguridad

- Crear tablas `profiles`, `matches`, `predictions` y `admin_users`.
- Configurar relaciones y restricciones.
- Activar Row Level Security.
- Crear políticas básicas de lectura y escritura.
- Cargar partidos de ejemplo.

### Etapa 3: Autenticación

- Implementar registro.
- Implementar inicio de sesión.
- Implementar cierre de sesión.
- Crear perfil básico del usuario.
- Proteger vistas internas.

### Etapa 4: Flujo de predicciones

- Mostrar lista de partidos.
- Mostrar estado de cada partido.
- Crear formulario de marcador por partido.
- Guardar predicción.
- Editar predicción antes del inicio.
- Bloquear edición cuando el partido ya comenzó.

### Etapa 5: Administración simple

- Crear vista administrativa mínima.
- Validar si el usuario actual existe en `admin_users`.
- Permitir cargar resultados reales.
- Permitir marcar partido como finalizado.
- Ejecutar cálculo de puntos.

### Etapa 6: Ranking

- Crear vista o consulta de ranking.
- Mostrar usuarios ordenados por puntaje.
- Mostrar puntos totales y datos básicos.
- Validar que el ranking cambie al cargar resultados.

### Etapa 7: Pulido móvil y demo

- Ajustar responsive mobile-first.
- Revisar estados vacíos y errores comunes.
- Cargar datos de prueba realistas.
- Preparar deploy.
- Hacer prueba completa de flujo usuario y administrador.

## 12. Lista de tareas técnicas

- Crear repositorio o estructura inicial del proyecto.
- Definir stack final.
- Crear proyecto en Supabase.
- Configurar `.env` con URL y anon key de Supabase.
- Instalar cliente de Supabase en el frontend si se usa React.
- Crear esquema SQL inicial.
- Crear políticas RLS.
- Crear seed de partidos.
- Implementar cliente Supabase.
- Implementar layout mobile-first.
- Implementar rutas o vistas principales:
  - inicio;
  - login/registro;
  - partidos;
  - ranking;
  - administración.
- Implementar manejo de sesión.
- Implementar CRUD mínimo de predicciones.
- Implementar bloqueo por fecha/hora de inicio.
- Implementar carga de resultados reales.
- Implementar cálculo de puntos.
- Implementar ranking general.
- Validar flujo completo con al menos dos usuarios de prueba.
- Preparar deploy.
- Documentar instrucciones básicas para correr localmente.

## 13. Riesgos o puntos a cuidar

- Seguridad de predicciones: un usuario no debe poder editar predicciones de otros.
- Bloqueo de edición: debe depender de la hora del servidor o base de datos cuando sea posible, no solo del reloj del navegador.
- RLS en Supabase: si queda mal configurado, puede exponer datos o bloquear operaciones legítimas.
- Administración: evitar que cualquier usuario pueda cargar resultados.
- Recalculo de puntos: debe ser consistente cuando se edita un resultado real.
- Zonas horarias: guardar fechas en `timestamp with time zone` y mostrar horarios de forma clara.
- Datos duplicados: impedir más de una predicción por usuario y partido.
- Alcance: no agregar funciones no esenciales antes de tener el flujo principal funcionando.
- Deploy: validar desde temprano que las variables de entorno y URLs públicas funcionen.
- Experiencia móvil: probar en pantallas pequeñas desde el inicio.

## 14. Recomendaciones para entregar una demo rápida

- Usar React + Vite si se quiere una base ordenada sin perder velocidad.
- Mantener una sola quiniela global para todos los usuarios.
- Cargar manualmente un set pequeño de partidos de ejemplo.
- Guardar resultados reales directamente en `matches`.
- Calcular puntos al momento de guardar o actualizar resultados.
- Usar una vista SQL para el ranking si es suficiente.
- Crear un panel admin mínimo, sin diseño avanzado.
- Priorizar los siguientes flujos para la demo:
  1. registro/login;
  2. captura de predicción;
  3. bloqueo por inicio de partido;
  4. carga de resultado;
  5. ranking actualizado.
- Evitar integraciones externas en la primera versión.
- Mantener textos, navegación y pantallas al mínimo.
- Preparar usuarios y partidos de prueba antes de presentar al cliente.

## Criterio de aceptación de la primera demo

La demo se considera lista cuando:

- Un usuario puede registrarse o iniciar sesión.
- Puede ver partidos disponibles.
- Puede guardar predicciones antes del inicio del partido.
- No puede modificar predicciones de partidos ya iniciados.
- Un administrador puede cargar resultados reales.
- El sistema asigna 5, 3 o 0 puntos según las reglas definidas.
- El ranking muestra usuarios ordenados por puntos.
- La app se puede usar correctamente desde celular.
- La app está desplegada o lista para desplegarse con instrucciones claras.
