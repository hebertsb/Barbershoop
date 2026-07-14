# Diseño: `autenticacion` (login Google + Facebook, enrutamiento por rol)

Fecha: 2026-07-14
Fase del plan: Fase 1, ítem 1 (`PLAN.md` §11 y §12.3)

## Alcance

Login de cliente/barbero/admin con Google o Facebook, creación automática de perfil, selección de barbería (multi-tenant), y enrutamiento inicial por rol. No incluye: pantallas reales de reservas/agenda/dashboard (llegan en sus propias funcionalidades), ni invitación de barberos por el admin (Fase 2), ni panel superadmin (Fase 4).

## Arquitectura

```
lib/funcionalidades/autenticacion/
├── dominio/
│   ├── enum_rol_usuario.dart       # cliente, barbero, admin, superadmin
│   └── modelo_perfil.dart          # id, email, barberiaId?, rol, nombre, urlFoto, telefono
├── datos/
│   └── repositorio_autenticacion.dart
└── presentacion/
    ├── pantallas/
    │   ├── pantalla_inicio_sesion.dart
    │   └── pantalla_seleccion_barberia.dart
    ├── controladores/
    │   └── controlador_autenticacion.dart   # Riverpod AsyncNotifier
    └── componentes/
        ├── boton_google.dart
        └── boton_facebook.dart
```

Flujo estricto: pantalla → controlador → repositorio → SDK nativo / Supabase. Las pantallas no llaman a Supabase ni a `google_sign_in`/`flutter_facebook_auth` directamente.

Paquetes nuevos en `pubspec.yaml`: `google_sign_in`, `flutter_facebook_auth`.

## Decisión: SDK nativo (no OAuth por navegador)

Login con `google_sign_in` / `flutter_facebook_auth` para obtener `idToken`, luego `Supabase.auth.signInWithIdToken(...)`. Un toque, sin salir de la app. Requiere:
- Google Cloud Console: Client ID Android (con SHA-1 del keystore de debug y del de release) + Client ID Web (para que Supabase valide el token).
- Meta for Developers: Facebook App ID + Client Token, configurados en `AndroidManifest.xml`/`strings.xml`.

También se activa en el dashboard de Supabase el enlazado automático de identidades por correo verificado (ver sección de Manejo de errores) para que Google y Facebook con el mismo correo terminen en una sola cuenta.

Esta configuración externa se hace de forma guiada, paso a paso, al momento de implementar (no es parte de este documento).

## Flujo de datos

1. Usuario toca "Continuar con Google" o "Continuar con Facebook" en `pantalla_inicio_sesion`.
2. `controlador_autenticacion` llama a `repositorio_autenticacion.iniciarSesionConGoogle()` (o Facebook).
3. Repositorio obtiene `idToken` del SDK nativo → `Supabase.auth.signInWithIdToken(provider: ..., idToken: ...)`.
4. Trigger SQL `manejar_nuevo_usuario` (ya existe, se amplía — ver Seguridad) crea la fila en `perfiles` si no existía: `rol='cliente'`, `barberia_id=null`, `email` copiado de `auth.users`.
5. `enrutador_app.dart` decide destino vía `redirect` de go_router, escuchando `Supabase.auth.onAuthStateChange`:
   - Sin sesión → `pantalla_inicio_sesion`.
   - Con sesión y `perfil.barberiaId == null` → `pantalla_seleccion_barberia`.
   - Con sesión y `barberiaId` asignado → pantalla provisional según `rol` (placeholder tipo "Hola, eres cliente de <barbería>" hasta que existan las pantallas reales de cada funcionalidad).
6. En `pantalla_seleccion_barberia`, el usuario elige una barbería activa de la lista → `controlador.asignarBarberia(id)` → `repositorio` hace `update perfiles set barberia_id = :id where id = auth.uid()`. Solo permitido una vez (ver Seguridad).

## Seguridad: cambio de rol y de barbería

**Regla: nadie se auto-asigna rol.** Solo `superadmin` puede cambiar `rol` de cualquier perfil. Un usuario solo puede fijar su propio `barberia_id` **una vez** (mientras esté `NULL`); cambiarlo después requiere `superadmin`.

### Cómo llega a existir un admin de barbería (sin panel todavía)

1. **Bootstrap del primer superadmin** (una sola vez en la vida del proyecto): te logueas normalmente con Google → se crea tu `perfiles` con `rol='cliente'`. Luego, **fuera de la app**, en Supabase SQL Editor:
   ```sql
   update perfiles set rol = 'superadmin' where email = 'tu-correo@gmail.com';
   ```
2. Como superadmin, insertas la fila en `barberias` (por SQL hasta que exista panel en Fase 4).
3. El dueño real de la barbería se loguea con su Google/Facebook en la app normal → se le crea `perfiles` con `rol='cliente'`, `barberia_id=null`.
4. Tú promueves esa fila por SQL:
   ```sql
   update perfiles set rol = 'admin', barberia_id = '<id-barberia>'
   where email = 'correo-del-dueño@gmail.com';
   ```

La invitación de barberos por el propio admin (Fase 2) se implementará más adelante como una función RPC `security definer` acotada (`rol='barbero'`, solo dentro de su propia `barberia_id`) — no se toca esta protección genérica para eso.

### Migración `0003_proteger_perfiles.sql`

- `alter table perfiles add column email text;`
- `manejar_nuevo_usuario()` (trigger existente en `0001`) se actualiza para copiar también `new.email`.
- Nuevo trigger `BEFORE UPDATE on perfiles` → función `evitar_escalada_privilegios()`:
  - Si `NEW.rol IS DISTINCT FROM OLD.rol` y `not es_superadmin()` → `raise exception`.
  - Si `NEW.barberia_id IS DISTINCT FROM OLD.barberia_id` y `OLD.barberia_id IS NOT NULL` y `not es_superadmin()` → `raise exception`.
  - Primera asignación (`OLD.barberia_id IS NULL`) queda permitida por el propio dueño de la fila — es la selección inicial de barbería.

La política `perfiles_update_propio` de `0002_rls_multi_tenant.sql` no cambia (sigue permitiendo `update` de la propia fila); este trigger es una capa adicional de defensa que sí restringe columnas, cosa que RLS por sí solo no puede hacer con `USING`/`WITH CHECK`.

## Manejo de errores

`repositorio_autenticacion.dart` envuelve toda llamada externa (SDK nativo + Supabase) en try/catch y relanza como excepción propia de `nucleo/errores/excepciones_app.dart`. Nunca deja pasar una excepción cruda de Google/Facebook/Supabase hacia el controlador.

| Caso | Detección | Excepción propia | UI |
|---|---|---|---|
| Cancela el selector de cuenta | SDK devuelve `null` / `LoginStatus.cancelled` | ninguna | vuelve al estado inicial, sin mensaje |
| Sin internet | `SocketException` / timeout | `ExcepcionRed` | "Sin conexión. Revisa tu internet e intenta de nuevo." |
| Token rechazado por Supabase | `AuthException` | `ExcepcionApp` | "No se pudo iniciar sesión. Intenta de nuevo." + `debugPrint` interno |
| Trigger `evitar_escalada_privilegios` bloquea update (defensa ante bug, no debería ocurrir vía app) | `PostgrestException` código `P0001` | `ExcepcionPermiso` | "No tienes permiso para realizar esta acción." |
| Lista de barberías activas vacía | query vacía | — | estado vacío: "No hay barberías disponibles todavía." |
| Falla `asignarBarberia()` a mitad de camino | red o permiso | según caso | se queda en `pantalla_seleccion_barberia` con el mensaje, no navega a medias |
| Sesión expira / refresh token inválido | `onAuthStateChange` emite `signedOut` | — | `enrutador_app` redirige solo a login (`refreshListenable`) |

**Mismo correo con Google y Facebook → misma cuenta, no dos.** Confirmado (2026-07-14): el dashboard actual de Supabase ya no tiene un toggle de "enlazado automático por correo" — lo quitaron por seguridad (evita que alguien secuestre una cuenta ajena con un correo no verificado). La forma correcta es enlazado explícito del lado de la app: con el usuario ya autenticado (por ejemplo con Google), en `ajustes` se ofrece la opción "Vincular Facebook" que llama a `Supabase.auth.linkIdentity(OAuthProvider.facebook)` — el usuario consciente vincula la segunda identidad a su misma cuenta (`auth.users.id`), sin depender de coincidencia automática de correo. Esto es Fase 2 (vive en `ajustes`, no en `autenticacion`); no bloquea el login inicial con cualquiera de los dos proveedores por separado.

## Testing

- `modelo_perfil`: roundtrip `desdeJson`/`aJson`.
- `controlador_autenticacion`: transiciones de estado con `RepositorioAutenticacion` fake (sin red real) — casos: login exitoso, cancelado, error de red, sin barbería asignada.
- Widget test `pantalla_inicio_sesion`: botones presentes, tap dispara el método correspondiente del controlador.
- SQL: verificar manualmente (o script) que un `update perfiles set rol='admin'` ejecutado como usuario no-superadmin falla con excepción.

## Fuera de alcance (queda para después, ya contemplado en el PLAN)

- Pantallas reales de reservas/agenda/dashboard por rol.
- Invitación de barberos por el admin (RPC dedicada, Fase 2).
- Panel superadmin para crear barberías/promover admins sin SQL manual (Fase 4).
