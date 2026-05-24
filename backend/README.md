# Backend / Supabase

Carpeta reservada para la configuracion de Supabase de la demo.

## Responsabilidad

- Definir el esquema SQL cuando inicie la etapa backend.
- Crear politicas Row Level Security.
- Crear vistas para ranking y consultas agregadas.
- Crear funciones SQL/RPC si hacen falta para calculo de puntos.
- Mantener datos seed de demo.

## Estructura

```text
backend/
├── README.md
├── supabase/
│   ├── schema.sql
│   ├── policies.sql
│   ├── views.sql
│   ├── functions.sql
│   └── seeds/
│       └── demo_data.sql
└── .gitkeep
```

## Estado actual

Los archivos SQL contienen comentarios base. Todavia no se crean tablas reales ni reglas de negocio en base de datos.
