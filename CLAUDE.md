# BarberApp — Contexto del proyecto

Plan completo del proyecto (leer siempre): @plan-app-barberia-flutter.md

## Qué es

App móvil Flutter para barberías (clientes reservan citas; barberos y admin gestionan agenda, inventario e ingresos). Multi-tenant desde el día 1 para venderse como SaaS. Backend: Supabase (sin servidor propio).

## Stack

- Flutter (Dart) + Riverpod (estado) + go_router (navegación) + supabase_flutter
- Supabase: Auth (Google), PostgreSQL con RLS por `barberia_id`, Storage, Edge Functions
- Migraciones SQL versionadas en `supabase/migraciones/`

## REGLAS DE CÓDIGO (OBLIGATORIAS)

### Idioma

- TODO en español: nombres de archivos, clases, funciones, variables, comentarios y tablas SQL.
- Ej.: `RepositorioCitas`, `obtenerHorariosDisponibles()`, `modelo_insumo.dart`, tabla `citas`.
- Excepción: palabras clave de Dart/Flutter y APIs de paquetes (`build`, `Widget`, `initState`) quedan en inglés.

### Estructura de 3 capas (NUNCA romperla)

- Organización por funcionalidades en `lib/funcionalidades/<nombre>/` con:
  - `datos/` → repositorios. ÚNICA capa que llama a Supabase.
  - `dominio/` → modelos y enums puros. Sin dependencias de Flutter ni Supabase.
  - `presentacion/pantallas/` → solo UI. CERO lógica de negocio, CERO llamadas a Supabase.
  - `presentacion/controladores/` → estado y lógica (Riverpod Notifier). Llaman a repositorios.
  - `presentacion/componentes/` → widgets pequeños reutilizables.
- Flujo SIEMPRE: pantalla → controlador → repositorio → Supabase.
- Lo compartido va en `lib/nucleo/` (configuracion, enrutador, componentes, utilidades, errores).

### Tamaño y limpieza

- Máximo ~300 líneas por archivo. Si una pantalla crece, EXTRAER widgets a `componentes/`.
- Una clase pública por archivo; nombre de archivo = clase en snake_case.
- Modelos inmutables con `copyWith`, `desdeJson`, `aJson`.
- Errores: los repositorios lanzan excepciones propias (`nucleo/errores/`); los controladores las traducen a mensajes de usuario.
- Ejecutar `dart format` y respetar `flutter_lints`.

### Base de datos

- TODA tabla lleva `barberia_id` + política RLS (multi-tenant estricto).
- Lógica crítica en funciones SQL (ej. `obtener_horarios_disponibles`): la disponibilidad y la anti-doble-reserva se resuelven en la DB, no en la app.
- Constraint único en citas: (barbero_id, fecha_hora).
- Nada de lógica nueva de configuración por barbería en columnas: usar la tabla `configuraciones_barberia` (clave-valor).

### Extensibilidad (sección 8 del PLAN.md)

- Servicios, promociones y ajustes son DATOS, no código.
- `pagos.metodo` y los estados son enums extensibles.
- Toda funcionalidad nueva = carpeta nueva en `funcionalidades/`, sin tocar las existentes.

## Comandos frecuentes

- `flutter run` — correr en dispositivo/emulador
- `flutter build apk --release` — APK de distribución (firmado con el keystore del proyecto)
- `flutter test` — tests (obligatorios para la lógica de horarios disponibles)
- `dart format lib/` — formateo

## Al implementar

- Seguir las fases del PLAN.md en orden (sección 11). Ahora: Fase 0/1.
- Commits pequeños por funcionalidad, mensajes en español.
- Nunca incluir claves/secretos en el código: usar variables de entorno.
