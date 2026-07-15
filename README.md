# BarberApp

App móvil (Flutter) para barberías. Los clientes reservan citas desde el teléfono; los barberos gestionan su agenda e insumos; el dueño/admin administra sucursales, servicios, inventario, promociones y ve reportes de ingresos. Pensada como **SaaS multi-tenant** desde el día uno: una sola app y una sola base de datos pueden atender a muchas barberías con los datos completamente aislados entre sí.

## Qué resuelve

- El cliente ya no llama o pasa por el local para agendar: elige sucursal, servicio, barbero y horario disponible, y paga por QR.
- El barbero ve su agenda del día, marca citas como completadas y reporta insumos dañados o agotados.
- El dueño ve de un vistazo cuánto se facturó hoy/este mes, gestiona el inventario y las promociones, y verifica los pagos por QR.

## Stack

- **Flutter** (Dart) — una sola app para cliente, barbero y admin, con la vista según el rol del usuario logueado.
- **Riverpod** — manejo de estado.
- **go_router** — navegación, con redirección automática según sesión/perfil/rol.
- **Supabase** — backend completo sin servidor propio: PostgreSQL, Auth (Google/Facebook), Storage, Row Level Security (RLS) para el aislamiento multi-tenant, y funciones SQL para la lógica crítica (ej. calcular horarios disponibles sin dobles reservas).

No hay backend propio: toda la lógica de servidor vive en funciones SQL de Postgres (dentro de Supabase) y, para integraciones externas puntuales, en Edge Functions.

## Estructura del proyecto

```
lib/
├── nucleo/                # Config, enrutador, componentes y utilidades compartidas
└── funcionalidades/        # Una carpeta por feature (autenticacion, reservas, citas, pagos, ...)
    └── <feature>/
        ├── datos/          # Repositorios — única capa que habla con Supabase
        ├── dominio/         # Modelos y enums puros, sin dependencias de Flutter
        └── presentacion/
            ├── pantallas/       # Solo UI, cero lógica de negocio
            ├── controladores/   # Estado y lógica (Riverpod)
            └── componentes/     # Widgets reutilizables

supabase/
└── migraciones/            # Esquema SQL versionado, se aplica a mano en el SQL Editor de Supabase
```

Flujo siempre igual: **pantalla → controlador → repositorio → Supabase**. Todo el código (nombres de archivos, clases, funciones, variables, tablas SQL) está en español; ver `CLAUDE.md` para las convenciones completas y `plan-app-barberia-flutter.md` para el plan de producto y fases.

## Estado actual

- ✅ Fase 0: proyecto Flutter + estructura de 3 capas + esquema SQL base + RLS multi-tenant.
- ✅ Autenticación: login nativo con Google y Facebook, creación automática de perfil, selección de barbería (onboarding multi-tenant), protección anti-escalada de privilegios (nadie se auto-asigna rol de admin), enrutamiento por sesión/perfil/rol.
- ⏳ En construcción: reservas, agenda del barbero, pagos por QR, inventario, reportes, panel de administración (ver fases en `plan-app-barberia-flutter.md`).

## Cómo correr el proyecto

1. `flutter pub get`
2. Copiar `.env.example` a `.env` y completar las credenciales (URL/keys de Supabase, client IDs de Google/Facebook) — nunca se sube al repo.
3. Aplicar las migraciones de `supabase/migraciones/` en orden, en el SQL Editor del proyecto de Supabase.
4. `flutter run`

## Tests

`flutter test` — cubre modelos de dominio, el controlador de autenticación y la lógica de redirección del enrutador.
