# Autenticación (Google + Facebook) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Login nativo con Google y Facebook, creación automática de perfil, selección de barbería (multi-tenant) y enrutamiento por rol, con protección anti-escalada de privilegios en la base de datos.

**Architecture:** Flujo estricto pantalla → controlador (Riverpod `AsyncNotifier`) → repositorio → SDK nativo (`google_sign_in` v7, `flutter_facebook_auth` v7) / Supabase. `go_router` decide la ruta activa según sesión + perfil vía un `redirect` que vive en un `Provider<GoRouter>`, refrescado por un `ChangeNotifier` que escucha tanto el stream de auth de Supabase como el propio estado del controlador.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod` 2.6.1), `go_router` 15.1.2, `supabase_flutter` 2.16.0 (`signInWithIdToken`), `google_sign_in` 7.2.0, `flutter_facebook_auth` 7.2.0, PostgreSQL/Supabase (trigger + RLS).

**Spec de referencia:** `docs/superpowers/specs/2026-07-14-autenticacion-design.md`

---

## Contexto ya verificado (no re-derivar)

- `pubspec.yaml` ya tiene `google_sign_in: ^7.2.0` y `flutter_facebook_auth: ^7.2.0` agregados y resueltos (`flutter pub get` corrido).
- `google_sign_in` 7.x cambió su API por completo respecto a v6: es un singleton `GoogleSignIn.instance`, se inicializa una sola vez con `initialize({serverClientId})`, y el login se hace con `authenticate()` (no `signIn()`). Cancelación lanza `GoogleSignInException(code: GoogleSignInExceptionCode.canceled)`, no devuelve `null`.
- `flutter_facebook_auth` 7.x usa `LoginTracking.limited` por defecto. En ese modo, `AccessToken` es un `LimitedToken` cuyo campo `tokenString` **es el idToken (JWT) real**, y trae su propio `nonce` generado por el SDK — ese mismo `nonce` hay que pasarlo a `signInWithIdToken`.
- `SupabaseClient.auth.signInWithIdToken({required OAuthProvider provider, required String idToken, String? accessToken, String? nonce})` — confirmado en `gotrue` 2.26.0. `OAuthProvider.google` y `OAuthProvider.facebook` existen como constantes.
- `.from(tabla).select().eq(...).maybeSingle()` devuelve `Future<Map<String, dynamic>?>` (`postgrest` 2.8.0, `PostgrestMap = Map<String, dynamic>`).
- Credenciales reales ya configuradas y guardadas:
  - `.env`: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID`, `FACEBOOK_APP_ID`, `FACEBOOK_CLIENT_TOKEN`.
  - `supabase/.env.admin`: secretos correspondientes (no se usan en la app).
  - Proveedores Google y Facebook activados en Supabase Dashboard.
- `android/app/build.gradle.kts` usa `minSdk = flutter.minSdkVersion`, que en Flutter 3.44 ya es 24 — cumple el mínimo que exige `google_sign_in_android` 7.2.15 (`minSdk = 24`). No hace falta tocar el gradle.
- No hay repositorio git todavía (`git status` falla con "not a git repository"). Este plan lo inicializa en la Tarea 1.

## Estructura de archivos

```
docs/superpowers/plans/2026-07-14-autenticacion.md   (este archivo)

supabase/migraciones/
└── 0003_proteger_perfiles.sql                        (nuevo)

android/app/src/main/res/values/
└── strings.xml                                       (nuevo)
android/app/src/main/AndroidManifest.xml               (modificar)

lib/nucleo/errores/excepciones_app.dart                 (modificar: + ExcepcionDesconocida)
lib/nucleo/configuracion/constantes.dart                 (modificar: + googleWebClientId)
lib/nucleo/enrutador/notificador_sesion.dart             (nuevo)
lib/nucleo/enrutador/enrutador_app.dart                  (reescribir como Provider<GoRouter>)
lib/main.dart                                            (modificar: ConsumerWidget + init Google)

lib/funcionalidades/autenticacion/
├── dominio/
│   ├── enum_rol_usuario.dart                          (nuevo)
│   ├── modelo_perfil.dart                             (nuevo)
│   └── modelo_barberia_resumen.dart                   (nuevo)
├── datos/
│   └── repositorio_autenticacion.dart                 (nuevo: interfaz + impl Supabase)
└── presentacion/
    ├── controladores/
    │   └── controlador_autenticacion.dart              (nuevo: AsyncNotifier + providers)
    ├── componentes/
    │   ├── boton_google.dart                           (nuevo)
    │   └── boton_facebook.dart                         (nuevo)
    └── pantallas/
        ├── pantalla_inicio_sesion.dart                 (nuevo)
        ├── pantalla_seleccion_barberia.dart             (nuevo)
        └── pantalla_bienvenida_provisional.dart         (nuevo)

test/funcionalidades/autenticacion/
├── dominio/
│   ├── enum_rol_usuario_test.dart                      (nuevo)
│   ├── modelo_perfil_test.dart                         (nuevo)
│   └── modelo_barberia_resumen_test.dart               (nuevo)
└── presentacion/
    ├── controlador_autenticacion_test.dart              (nuevo)
    └── pantalla_inicio_sesion_test.dart                 (nuevo)
```

---

### Task 1: Inicializar git y fijar la línea base

**Files:**
- Ninguno nuevo — commitea todo lo existente del scaffold de Fase 0 + el spec aprobado.

- [ ] **Step 1: Verificar qué se va a incluir**

Run: `git status`
Expected: lista larga de "Untracked files" (todo el proyecto, nada trackeado aún).

- [ ] **Step 2: Confirmar que los secretos están ignorados**

Run: `git status --porcelain | grep -E "\.env$|\.env\.admin$"`
Expected: sin salida (si aparece algo, PARAR — no continuar hasta corregir `.gitignore`).

- [ ] **Step 3: Commit inicial**

```bash
git init
git add .
git commit -m "chore: scaffold inicial BarberApp (Fase 0) + spec de autenticacion"
```

---

### Task 2: Migración SQL — email en perfiles + anti escalada de privilegios

**Files:**
- Create: `supabase/migraciones/0003_proteger_perfiles.sql`

- [ ] **Step 1: Escribir la migración**

```sql
-- ============================================================================
-- BarberApp - Protección de perfiles: email + anti escalada de privilegios
-- ============================================================================

alter table perfiles add column email text;

-- Reemplaza el trigger de 0001 para copiar también el email.
create or replace function manejar_nuevo_usuario()
returns trigger as $$
begin
  insert into public.perfiles (id, email, nombre, url_foto)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- Nadie cambia su propio rol; nadie cambia su barberia_id una vez asignada.
-- Solo superadmin puede saltarse esto (bootstrap y promoción de admins).
create or replace function evitar_escalada_privilegios()
returns trigger as $$
begin
  if new.rol is distinct from old.rol and not es_superadmin() then
    raise exception 'Solo un superadmin puede cambiar el rol.';
  end if;

  if new.barberia_id is distinct from old.barberia_id
     and old.barberia_id is not null
     and not es_superadmin() then
    raise exception 'No puedes cambiar de barbería una vez asignada.';
  end if;

  return new;
end;
$$ language plpgsql set search_path = public;

create trigger trg_perfiles_evitar_escalada_privilegios
  before update on perfiles
  for each row execute function evitar_escalada_privilegios();
```

- [ ] **Step 2: Aplicar la migración en Supabase**

Abre el SQL Editor del dashboard de Supabase (proyecto `barberia-app`, el mismo donde ya activaste Google/Facebook) y pega el contenido completo del archivo. Ejecuta.

Expected: "Success. No rows returned."

- [ ] **Step 3: Verificación manual de la protección (una sola vez, no es parte del suite automatizado)**

En el SQL Editor, todavía como superusuario (esto se ejecuta con el rol de servicio, así que no está sujeto a RLS — es solo para confirmar que el trigger existe y su lógica es correcta antes de probarlo con un usuario real más adelante):

```sql
select tgname from pg_trigger where tgrelid = 'perfiles'::regclass;
```

Expected: incluye `trg_perfiles_evitar_escalada_privilegios` en la lista (junto con `trg_perfiles_actualizado_en` de la migración 0001).

- [ ] **Step 4: Commit**

```bash
git add supabase/migraciones/0003_proteger_perfiles.sql
git commit -m "feat(db): agregar email a perfiles y trigger anti escalada de privilegios"
```

---

### Task 3: Configuración nativa de Android para Facebook Login

**Files:**
- Create: `android/app/src/main/res/values/strings.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Crear `strings.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">BarberApp</string>
    <string name="facebook_app_id">27659270717087204</string>
    <string name="fb_login_protocol_scheme">fb27659270717087204</string>
    <string name="facebook_client_token">1dea4c61fd0b419291c286aeaf312f20</string>
</resources>
```

- [ ] **Step 2: Agregar meta-data y activities de Facebook al `AndroidManifest.xml`**

Dentro de `<application>`, justo después del bloque `<activity android:name=".MainActivity" ...>...</activity>` (antes del comentario `<!-- Don't delete the meta-data below. -->`), agrega:

```xml
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id" />
        <meta-data
            android:name="com.facebook.sdk.ClientToken"
            android:value="@string/facebook_client_token" />
        <activity
            android:name="com.facebook.FacebookActivity"
            android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
            android:label="@string/app_name" />
        <activity
            android:name="com.facebook.CustomTabActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="@string/fb_login_protocol_scheme" />
            </intent-filter>
        </activity>
```

El archivo completo debe quedar así:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="barber_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id" />
        <meta-data
            android:name="com.facebook.sdk.ClientToken"
            android:value="@string/facebook_client_token" />
        <activity
            android:name="com.facebook.FacebookActivity"
            android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
            android:label="@string/app_name" />
        <activity
            android:name="com.facebook.CustomTabActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="@string/fb_login_protocol_scheme" />
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

- [ ] **Step 3: Verificar que el proyecto Android sigue compilando**

Run: `flutter build apk --debug`
Expected: termina con `Built build\app\outputs\flutter-apk\app-debug.apk` sin errores de manifest merger.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/res/values/strings.xml android/app/src/main/AndroidManifest.xml
git commit -m "chore(android): configurar SDK nativo de Facebook Login"
```

---

### Task 4: `ExcepcionDesconocida` en el núcleo de errores

**Files:**
- Modify: `lib/nucleo/errores/excepciones_app.dart`

- [ ] **Step 1: Agregar la excepción**

Al final del archivo, después de `ExcepcionDatosNoEncontrados`:

```dart
class ExcepcionDesconocida extends ExcepcionApp {
  const ExcepcionDesconocida([super.mensaje = 'No se pudo completar la acción. Intenta de nuevo.']);
}
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/nucleo/errores/excepciones_app.dart
git commit -m "feat(nucleo): agregar ExcepcionDesconocida para fallos genericos de SDKs externos"
```

---

### Task 5: `Constantes.googleWebClientId`

**Files:**
- Modify: `lib/nucleo/configuracion/constantes.dart`

- [ ] **Step 1: Agregar el getter**

El archivo completo queda:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  Constantes._();

  static String get urlSupabase => dotenv.get('SUPABASE_URL');
  static String get claveAnonSupabase => dotenv.get('SUPABASE_ANON_KEY');
  static String get googleWebClientId => dotenv.get('GOOGLE_WEB_CLIENT_ID');
}
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/nucleo/configuracion/constantes.dart
git commit -m "feat(nucleo): exponer GOOGLE_WEB_CLIENT_ID en Constantes"
```

---

### Task 6: Dominio — `RolUsuario`

**Files:**
- Create: `lib/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart`
- Test: `test/funcionalidades/autenticacion/dominio/enum_rol_usuario_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';

void main() {
  group('RolUsuario', () {
    test('desdeTexto reconoce cada valor valido', () {
      expect(RolUsuario.desdeTexto('cliente'), RolUsuario.cliente);
      expect(RolUsuario.desdeTexto('barbero'), RolUsuario.barbero);
      expect(RolUsuario.desdeTexto('admin'), RolUsuario.admin);
      expect(RolUsuario.desdeTexto('superadmin'), RolUsuario.superadmin);
    });

    test('desdeTexto usa cliente como valor por defecto ante texto desconocido', () {
      expect(RolUsuario.desdeTexto('lo-que-sea'), RolUsuario.cliente);
    });
  });
}
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `flutter test test/funcionalidades/autenticacion/dominio/enum_rol_usuario_test.dart`
Expected: FAIL — `Error: Not found: 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart'`

- [ ] **Step 3: Implementar**

```dart
enum RolUsuario {
  cliente,
  barbero,
  admin,
  superadmin;

  static RolUsuario desdeTexto(String texto) {
    return RolUsuario.values.firstWhere(
      (valor) => valor.name == texto,
      orElse: () => RolUsuario.cliente,
    );
  }
}
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `flutter test test/funcionalidades/autenticacion/dominio/enum_rol_usuario_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart test/funcionalidades/autenticacion/dominio/enum_rol_usuario_test.dart
git commit -m "feat(autenticacion): agregar enum RolUsuario"
```

---

### Task 7: Dominio — `ModeloPerfil`

**Files:**
- Create: `lib/funcionalidades/autenticacion/dominio/modelo_perfil.dart`
- Test: `test/funcionalidades/autenticacion/dominio/modelo_perfil_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';

void main() {
  test('desdeJson y aJson hacen roundtrip completo', () {
    final json = {
      'id': 'uid-1',
      'email': 'ana@example.com',
      'barberia_id': 'barberia-1',
      'rol': 'admin',
      'nombre': 'Ana',
      'url_foto': 'https://ejemplo.com/foto.png',
      'telefono': '70000000',
    };

    final perfil = ModeloPerfil.desdeJson(json);

    expect(perfil.id, 'uid-1');
    expect(perfil.email, 'ana@example.com');
    expect(perfil.barberiaId, 'barberia-1');
    expect(perfil.rol, RolUsuario.admin);
    expect(perfil.nombre, 'Ana');
    expect(perfil.urlFoto, 'https://ejemplo.com/foto.png');
    expect(perfil.telefono, '70000000');
    expect(perfil.aJson(), json);
  });

  test('desdeJson admite barberia_id nulo (perfil recien creado)', () {
    final perfil = ModeloPerfil.desdeJson({
      'id': 'uid-2',
      'email': 'nuevo@example.com',
      'barberia_id': null,
      'rol': 'cliente',
      'nombre': null,
      'url_foto': null,
      'telefono': null,
    });

    expect(perfil.barberiaId, isNull);
    expect(perfil.rol, RolUsuario.cliente);
  });

  test('copyWith actualiza barberiaId sin tocar el resto', () {
    final original = ModeloPerfil.desdeJson({
      'id': 'uid-3',
      'email': 'x@example.com',
      'barberia_id': null,
      'rol': 'cliente',
      'nombre': 'X',
      'url_foto': null,
      'telefono': null,
    });

    final actualizado = original.copyWith(barberiaId: 'barberia-9');

    expect(actualizado.barberiaId, 'barberia-9');
    expect(actualizado.id, original.id);
    expect(actualizado.nombre, original.nombre);
  });
}
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `flutter test test/funcionalidades/autenticacion/dominio/modelo_perfil_test.dart`
Expected: FAIL — archivo `modelo_perfil.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
import 'enum_rol_usuario.dart';

class ModeloPerfil {
  const ModeloPerfil({
    required this.id,
    required this.email,
    required this.barberiaId,
    required this.rol,
    required this.nombre,
    required this.urlFoto,
    required this.telefono,
  });

  final String id;
  final String email;
  final String? barberiaId;
  final RolUsuario rol;
  final String? nombre;
  final String? urlFoto;
  final String? telefono;

  factory ModeloPerfil.desdeJson(Map<String, dynamic> json) {
    return ModeloPerfil(
      id: json['id'] as String,
      email: json['email'] as String,
      barberiaId: json['barberia_id'] as String?,
      rol: RolUsuario.desdeTexto(json['rol'] as String),
      nombre: json['nombre'] as String?,
      urlFoto: json['url_foto'] as String?,
      telefono: json['telefono'] as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'email': email,
      'barberia_id': barberiaId,
      'rol': rol.name,
      'nombre': nombre,
      'url_foto': urlFoto,
      'telefono': telefono,
    };
  }

  ModeloPerfil copyWith({
    String? barberiaId,
    RolUsuario? rol,
    String? nombre,
    String? urlFoto,
    String? telefono,
  }) {
    return ModeloPerfil(
      id: id,
      email: email,
      barberiaId: barberiaId ?? this.barberiaId,
      rol: rol ?? this.rol,
      nombre: nombre ?? this.nombre,
      urlFoto: urlFoto ?? this.urlFoto,
      telefono: telefono ?? this.telefono,
    );
  }
}
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `flutter test test/funcionalidades/autenticacion/dominio/modelo_perfil_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/funcionalidades/autenticacion/dominio/modelo_perfil.dart test/funcionalidades/autenticacion/dominio/modelo_perfil_test.dart
git commit -m "feat(autenticacion): agregar ModeloPerfil"
```

---

### Task 8: Dominio — `ModeloBarberiaResumen`

**Files:**
- Create: `lib/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart`
- Test: `test/funcionalidades/autenticacion/dominio/modelo_barberia_resumen_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';

void main() {
  test('desdeJson mapea id y nombre', () {
    final barberia = ModeloBarberiaResumen.desdeJson({'id': 'b1', 'nombre': 'Barberia Central'});
    expect(barberia.id, 'b1');
    expect(barberia.nombre, 'Barberia Central');
  });
}
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `flutter test test/funcionalidades/autenticacion/dominio/modelo_barberia_resumen_test.dart`
Expected: FAIL — archivo no existe.

- [ ] **Step 3: Implementar**

```dart
class ModeloBarberiaResumen {
  const ModeloBarberiaResumen({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory ModeloBarberiaResumen.desdeJson(Map<String, dynamic> json) {
    return ModeloBarberiaResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }
}
```

Nota: esta es una vista mínima (solo `id`+`nombre`) solo para la pantalla de selección. Cuando se construya `administracion` (Fase 1, item 2) con el modelo completo de barbería, este archivo se mantiene separado — evita acoplar `autenticacion` a una funcionalidad que todavía no existe.

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `flutter test test/funcionalidades/autenticacion/dominio/modelo_barberia_resumen_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart test/funcionalidades/autenticacion/dominio/modelo_barberia_resumen_test.dart
git commit -m "feat(autenticacion): agregar ModeloBarberiaResumen"
```

---

### Task 9: Datos — `RepositorioAutenticacion`

**Files:**
- Create: `lib/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart`

No lleva test unitario propio (es una capa delgada sobre SDKs de plataforma que no se puede ejercitar sin dispositivo real); el controlador de la Tarea 10 se testea con un fake que implementa esta misma interfaz.

- [ ] **Step 1: Implementar interfaz + implementación Supabase**

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_barberia_resumen.dart';
import '../dominio/modelo_perfil.dart';

abstract class RepositorioAutenticacion {
  Future<void> iniciarSesionConGoogle();
  Future<void> iniciarSesionConFacebook();
  Future<ModeloPerfil?> obtenerPerfilActual();
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas();
  Future<void> asignarBarberia(String barberiaId);
  Future<void> cerrarSesion();
}

class RepositorioAutenticacionSupabase implements RepositorioAutenticacion {
  RepositorioAutenticacionSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<void> iniciarSesionConGoogle() async {
    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;
      if (idToken == null) {
        throw const ExcepcionDesconocida();
      }
      await _cliente.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('GoogleSignInException: ${e.description}');
      throw const ExcepcionDesconocida();
    } on SocketException {
      throw const ExcepcionRed();
    } on AuthException catch (e) {
      debugPrint('AuthException Google: ${e.message}');
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> iniciarSesionConFacebook() async {
    try {
      final resultado = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (resultado.status == LoginStatus.cancelled) return;
      if (resultado.status != LoginStatus.success) {
        throw const ExcepcionDesconocida();
      }
      final token = resultado.accessToken;
      if (token is! LimitedToken) {
        throw const ExcepcionDesconocida();
      }
      await _cliente.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: token.tokenString,
        nonce: token.nonce,
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on AuthException catch (e) {
      debugPrint('AuthException Facebook: ${e.message}');
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final fila = await _cliente.from('perfiles').select().eq('id', uid).maybeSingle();
      if (fila == null) return null;
      return ModeloPerfil.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async {
    try {
      final filas = await _cliente
          .from('barberias')
          .select('id, nombre')
          .eq('activo', true)
          .order('nombre');
      return filas.map(ModeloBarberiaResumen.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> asignarBarberia(String barberiaId) async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) throw const ExcepcionPermiso();
    try {
      await _cliente.from('perfiles').update({'barberia_id': barberiaId}).eq('id', uid);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw const ExcepcionPermiso();
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await _cliente.auth.signOut();
    await GoogleSignIn.instance.signOut();
    await FacebookAuth.instance.logOut();
  }
}
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart
git commit -m "feat(autenticacion): agregar RepositorioAutenticacion (Google, Facebook, Supabase)"
```

---

### Task 10: Presentación — `ControladorAutenticacion`

**Files:**
- Create: `lib/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart`
- Test: `test/funcionalidades/autenticacion/presentacion/controlador_autenticacion_test.dart`

- [ ] **Step 1: Escribir el test que falla (con un fake del repositorio)**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import 'package:barber_app/nucleo/errores/excepciones_app.dart';

class RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  ModeloPerfil? perfilActual;
  Object? errorAlIniciarSesion;
  bool cancelarGoogle = false;

  @override
  Future<void> iniciarSesionConGoogle() async {
    if (errorAlIniciarSesion != null) throw errorAlIniciarSesion!;
    if (cancelarGoogle) return;
    perfilActual = const ModeloPerfil(
      id: 'uid-1',
      email: 'ana@example.com',
      barberiaId: null,
      rol: RolUsuario.cliente,
      nombre: 'Ana',
      urlFoto: null,
      telefono: null,
    );
  }

  @override
  Future<void> iniciarSesionConFacebook() => iniciarSesionConGoogle();

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async => perfilActual;

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async => [];

  @override
  Future<void> asignarBarberia(String barberiaId) async {
    perfilActual = perfilActual?.copyWith(barberiaId: barberiaId);
  }

  @override
  Future<void> cerrarSesion() async {
    perfilActual = null;
  }
}

void main() {
  test('build() sin sesion previa devuelve null', () async {
    final falso = RepositorioAutenticacionFalso();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    final perfil = await contenedor.read(controladorAutenticacionProvider.future);
    expect(perfil, isNull);
  });

  test('iniciarSesionConGoogle exitoso deja el perfil en el estado', () async {
    final falso = RepositorioAutenticacionFalso();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.value?.email, 'ana@example.com');
  });

  test('iniciarSesionConGoogle cancelado no deja error ni perfil', () async {
    final falso = RepositorioAutenticacionFalso()..cancelarGoogle = true;
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.hasError, isFalse);
    expect(estado.value, isNull);
  });

  test('error de red al iniciar sesion queda expuesto como ExcepcionRed', () async {
    final falso = RepositorioAutenticacionFalso()..errorAlIniciarSesion = const ExcepcionRed();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.hasError, isTrue);
    expect(estado.error, isA<ExcepcionRed>());
  });

  test('asignarBarberia actualiza barberiaId en el perfil', () async {
    final falso = RepositorioAutenticacionFalso();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();
    await contenedor.read(controladorAutenticacionProvider.notifier).asignarBarberia('barberia-1');

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.value?.barberiaId, 'barberia-1');
  });
}
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `flutter test test/funcionalidades/autenticacion/presentacion/controlador_autenticacion_test.dart`
Expected: FAIL — `controlador_autenticacion.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_autenticacion.dart';
import '../../dominio/modelo_barberia_resumen.dart';
import '../../dominio/modelo_perfil.dart';

final repositorioAutenticacionProvider = Provider<RepositorioAutenticacion>((ref) {
  return RepositorioAutenticacionSupabase();
});

class ControladorAutenticacion extends AsyncNotifier<ModeloPerfil?> {
  @override
  Future<ModeloPerfil?> build() {
    return ref.read(repositorioAutenticacionProvider).obtenerPerfilActual();
  }

  Future<void> iniciarSesionConGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.iniciarSesionConGoogle();
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> iniciarSesionConFacebook() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.iniciarSesionConFacebook();
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> asignarBarberia(String barberiaId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.asignarBarberia(barberiaId);
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> cerrarSesion() async {
    await ref.read(repositorioAutenticacionProvider).cerrarSesion();
    state = const AsyncData(null);
  }
}

final controladorAutenticacionProvider =
    AsyncNotifierProvider<ControladorAutenticacion, ModeloPerfil?>(
  ControladorAutenticacion.new,
);

final barberiasActivasProvider = FutureProvider.autoDispose((ref) {
  return ref.read(repositorioAutenticacionProvider).obtenerBarberiasActivas();
});
```

Nota de diseño: el controlador no reformatea las excepciones a texto — `ExcepcionRed`/`ExcepcionPermiso`/`ExcepcionDesconocida` ya sobrescriben `toString()` con el mensaje amigable en español, y llegan aquí ya traducidas desde el repositorio (nunca una excepción cruda de Supabase/Google/Facebook). Las pantallas muestran `estado.error.toString()` directamente.

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `flutter test test/funcionalidades/autenticacion/presentacion/controlador_autenticacion_test.dart`
Expected: `All tests passed!` (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart test/funcionalidades/autenticacion/presentacion/controlador_autenticacion_test.dart
git commit -m "feat(autenticacion): agregar ControladorAutenticacion"
```

---

### Task 11: Presentación — botones de Google y Facebook

**Files:**
- Create: `lib/funcionalidades/autenticacion/presentacion/componentes/boton_google.dart`
- Create: `lib/funcionalidades/autenticacion/presentacion/componentes/boton_facebook.dart`

- [ ] **Step 1: `boton_google.dart`**

```dart
import 'package:flutter/material.dart';

class BotonGoogle extends StatelessWidget {
  const BotonGoogle({super.key, required this.cargando, required this.alPresionar});

  final bool cargando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: cargando ? null : alPresionar,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Continuar con Google'),
      ),
    );
  }
}
```

- [ ] **Step 2: `boton_facebook.dart`**

```dart
import 'package:flutter/material.dart';

class BotonFacebook extends StatelessWidget {
  const BotonFacebook({super.key, required this.cargando, required this.alPresionar});

  final bool cargando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: cargando ? null : alPresionar,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1877F2)),
        icon: const Icon(Icons.facebook, size: 24),
        label: const Text('Continuar con Facebook'),
      ),
    );
  }
}
```

Nota: se usan iconos de Material en vez de los logos de marca — evita meter una pipeline de assets SVG en esta tarea. Cambiar por los logos oficiales es un ajuste visual aislado para cuando se trabaje `ajustes`/branding, no bloquea el login.

- [ ] **Step 3: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/funcionalidades/autenticacion/presentacion/componentes/
git commit -m "feat(autenticacion): agregar BotonGoogle y BotonFacebook"
```

---

### Task 12: Presentación — `PantallaInicioSesion`

**Files:**
- Create: `lib/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart`
- Test: `test/funcionalidades/autenticacion/presentacion/pantalla_inicio_sesion_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';

class _RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  bool googleLlamado = false;

  @override
  Future<void> iniciarSesionConGoogle() async {
    googleLlamado = true;
  }

  @override
  Future<void> iniciarSesionConFacebook() async {}

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async => null;

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async => [];

  @override
  Future<void> asignarBarberia(String barberiaId) async {}

  @override
  Future<void> cerrarSesion() async {}
}

void main() {
  testWidgets('muestra los dos botones y dispara login de Google al tocar', (tester) async {
    final falso = _RepositorioAutenticacionFalso();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioAutenticacionProvider.overrideWithValue(falso)],
        child: const MaterialApp(home: PantallaInicioSesion()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Continuar con Facebook'), findsOneWidget);

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(falso.googleLlamado, isTrue);
  });
}
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `flutter test test/funcionalidades/autenticacion/presentacion/pantalla_inicio_sesion_test.dart`
Expected: FAIL — `pantalla_inicio_sesion.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/boton_facebook.dart';
import '../componentes/boton_google.dart';
import '../controladores/controlador_autenticacion.dart';

class PantallaInicioSesion extends ConsumerWidget {
  const PantallaInicioSesion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorAutenticacionProvider);

    ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    final cargando = estado.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BarberApp',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                BotonGoogle(
                  cargando: cargando,
                  alPresionar: () => ref
                      .read(controladorAutenticacionProvider.notifier)
                      .iniciarSesionConGoogle(),
                ),
                const SizedBox(height: 16),
                BotonFacebook(
                  cargando: cargando,
                  alPresionar: () => ref
                      .read(controladorAutenticacionProvider.notifier)
                      .iniciarSesionConFacebook(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `flutter test test/funcionalidades/autenticacion/presentacion/pantalla_inicio_sesion_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart test/funcionalidades/autenticacion/presentacion/pantalla_inicio_sesion_test.dart
git commit -m "feat(autenticacion): agregar PantallaInicioSesion"
```

---

### Task 13: Presentación — `PantallaSeleccionBarberia` y `PantallaBienvenidaProvisional`

**Files:**
- Create: `lib/funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart`
- Create: `lib/funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart`

Sin test dedicado: son integraciones directas de piezas ya testeadas (`controladorAutenticacionProvider`, `barberiasActivasProvider`) sin lógica propia que valga la pena aislar; se verifican manualmente en la Tarea 16.

- [ ] **Step 1: `pantalla_seleccion_barberia.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controladores/controlador_autenticacion.dart';

class PantallaSeleccionBarberia extends ConsumerWidget {
  const PantallaSeleccionBarberia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberias = ref.watch(barberiasActivasProvider);

    ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu barbería')),
      body: barberias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(child: Text('No hay barberías disponibles todavía.'));
          }
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, indice) {
              final barberia = lista[indice];
              return ListTile(
                title: Text(barberia.nombre),
                onTap: () => ref
                    .read(controladorAutenticacionProvider.notifier)
                    .asignarBarberia(barberia.id),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: `pantalla_bienvenida_provisional.dart`**

```dart
import 'package:flutter/material.dart';

import '../../dominio/enum_rol_usuario.dart';

class PantallaBienvenidaProvisional extends StatelessWidget {
  const PantallaBienvenidaProvisional({super.key, required this.rol, required this.nombre});

  final RolUsuario rol;
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Hola${nombre != null ? ', $nombre' : ''}, eres ${rol.name}'),
      ),
    );
  }
}
```

- [ ] **Step 3: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart lib/funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart
git commit -m "feat(autenticacion): agregar PantallaSeleccionBarberia y PantallaBienvenidaProvisional"
```

---

### Task 14: Núcleo — `NotificadorSesion`

**Files:**
- Create: `lib/nucleo/enrutador/notificador_sesion.dart`

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/foundation.dart';

/// ChangeNotifier plano usado como `refreshListenable` de go_router.
/// Se dispara manualmente desde donde haga falta re-evaluar el redirect:
/// eventos de auth de Supabase y cambios en el estado del controlador.
class NotificadorSesion extends ChangeNotifier {
  void notificar() => notifyListeners();
}
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/nucleo/enrutador/notificador_sesion.dart
git commit -m "feat(nucleo): agregar NotificadorSesion para refrescar go_router"
```

---

### Task 15: Núcleo — reescribir `enrutador_app.dart` como `Provider<GoRouter>`

**Files:**
- Modify: `lib/nucleo/enrutador/enrutador_app.dart`

- [ ] **Step 1: Reescribir el archivo completo**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import '../../funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart';
import '../configuracion/cliente_supabase.dart';
import 'notificador_sesion.dart';

final enrutadorAppProvider = Provider<GoRouter>((ref) {
  final notificador = NotificadorSesion();

  final suscripcionAuth = ClienteSupabase.instancia.auth.onAuthStateChange.listen((_) {
    notificador.notificar();
  });
  ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
    notificador.notificar();
  });

  ref.onDispose(() {
    suscripcionAuth.cancel();
    notificador.dispose();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notificador,
    redirect: (context, state) {
      final sesion = ClienteSupabase.instancia.auth.currentSession;
      final enLogin = state.matchedLocation == '/login';

      if (sesion == null) {
        return enLogin ? null : '/login';
      }

      final estadoPerfil = ref.read(controladorAutenticacionProvider);
      if (estadoPerfil.isLoading) return null;

      final perfil = estadoPerfil.valueOrNull;
      if (perfil == null) {
        return enLogin ? null : '/login';
      }

      final enSeleccion = state.matchedLocation == '/seleccion-barberia';
      if (perfil.barberiaId == null) {
        return enSeleccion ? null : '/seleccion-barberia';
      }

      if (enLogin || enSeleccion) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const PantallaInicioSesion(),
      ),
      GoRoute(
        path: '/seleccion-barberia',
        builder: (context, state) => const PantallaSeleccionBarberia(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final perfil = ref.read(controladorAutenticacionProvider).valueOrNull;
          return PantallaBienvenidaProvisional(
            rol: perfil?.rol ?? RolUsuario.cliente,
            nombre: perfil?.nombre,
          );
        },
      ),
    ],
  );
});
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: `No issues found!` (nótese que la Tarea 16 todavía tiene que actualizar `main.dart` para que compile end-to-end; si `flutter analyze` marca error en `main.dart` por el tipo de `enrutadorApp` que ya no existe, es esperado hasta cerrar esa tarea).

- [ ] **Step 3: Commit**

```bash
git add lib/nucleo/enrutador/enrutador_app.dart
git commit -m "refactor(nucleo): enrutador_app como Provider<GoRouter> con redirect por sesion/perfil/rol"
```

---

### Task 16: `main.dart` — inicializar Google Sign In y usar el router por Riverpod

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Reescribir el archivo completo**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'nucleo/configuracion/cliente_supabase.dart';
import 'nucleo/configuracion/constantes.dart';
import 'nucleo/configuracion/tema_app.dart';
import 'nucleo/enrutador/enrutador_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ClienteSupabase.inicializar();
  await GoogleSignIn.instance.initialize(serverClientId: Constantes.googleWebClientId);
  runApp(const ProviderScope(child: BarberApp()));
}

class BarberApp extends ConsumerWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrutador = ref.watch(enrutadorAppProvider);
    return MaterialApp.router(
      title: 'BarberApp',
      theme: TemaApp.claro,
      routerConfig: enrutador,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: inicializar Google Sign In y usar enrutadorAppProvider en main.dart"
```

---

### Task 17: Actualizar el smoke test de `main.dart`

**Files:**
- Modify: `test/widget_test.dart`

El smoke test actual de Fase 0 (`test/widget_test.dart`) monta un `GoRouter` de juguete y no depende de `main.dart`, así que sigue pasando tal cual. Verifícalo para confirmar que nada de este plan lo rompió.

- [ ] **Step 1: Correr toda la suite**

Run: `flutter test`
Expected: `All tests passed!` (deben aparecer 1 (`widget_test.dart`) + 2 (`enum_rol_usuario_test.dart`) + 3 (`modelo_perfil_test.dart`) + 1 (`modelo_barberia_resumen_test.dart`) + 5 (`controlador_autenticacion_test.dart`) + 1 (`pantalla_inicio_sesion_test.dart`) = 13 tests).

- [ ] **Step 2: Si algo falla, arreglar antes de seguir** (no hay cambios de código esperados en este paso si las tareas anteriores se hicieron bien)

---

### Task 18: Verificación manual end-to-end en dispositivo/emulador

Este paso no es automatizable — requiere un dispositivo Android real o emulador con Google Play Services, y probar el flujo completo con tu cuenta.

**Files:** ninguno.

- [ ] **Step 1: Compilar y correr**

Run: `flutter run`
Expected: la app abre en `/login` (sin sesión activa) mostrando "BarberApp" y los dos botones.

- [ ] **Step 2: Probar login con Google**

Toca "Continuar con Google", elige tu cuenta Gmail (la misma que agregaste como test user en Google Cloud Console). Verifica que después del login la app navega automáticamente a la pantalla "Elige tu barbería" (porque tu perfil recién creado tiene `barberia_id = null`).

- [ ] **Step 3: Verificar en Supabase que el perfil se creó bien**

En el SQL Editor de Supabase: `select id, email, rol, barberia_id from perfiles order by creado_en desc limit 1;`
Expected: una fila nueva con tu email, `rol = 'cliente'`, `barberia_id = null`.

- [ ] **Step 4: Probar la protección anti-escalada (una vez, manual)**

Todavía en el SQL Editor, simula lo que pasaría si tu propio usuario (no superadmin) intentara cambiarse el rol — reemplaza `<tu-uid>` por el `id` que viste en el Step 3, y ejecuta esto como si fuera una llamada autenticada de ese usuario:

```sql
set local role authenticated;
set local "request.jwt.claims" = '{"sub": "<tu-uid>"}';
update perfiles set rol = 'admin' where id = '<tu-uid>';
```

Expected: error `Solo un superadmin puede cambiar el rol.` — si en cambio se actualiza sin error, el trigger de la Tarea 2 no quedó bien aplicado; revisar antes de seguir.

- [ ] **Step 5: Bootstrap manual a superadmin (una sola vez en la vida del proyecto)**

```sql
update perfiles set rol = 'superadmin' where email = 'tu-correo@gmail.com';
```

- [ ] **Step 6: Crear tu primera barbería y probar la selección**

```sql
insert into barberias (nombre) values ('Mi Primera Barbería');
```

Vuelve a la app (o haz hot restart), en la pantalla "Elige tu barbería" debe aparecer "Mi Primera Barbería" en la lista. Tócala.

Expected: la app navega a la pantalla de bienvenida provisional mostrando tu rol actual.

- [ ] **Step 7: Probar login con Facebook**

Cierra sesión (todavía no hay botón de cerrar sesión en la UI — usa `await Supabase.instance.client.auth.signOut()` desde el DevTools console de Flutter, o reinstala la app). Repite el flujo con "Continuar con Facebook" usando tu cuenta de Facebook (ya sos Administrador de la app de Meta, así que funciona sin agregar testers).

Expected: mismo flujo — perfil nuevo creado, pantalla de selección de barbería, etc.

- [ ] **Step 8: Commit final si todo pasó**

```bash
git add -A
git status
```

Revisa que no aparezca nada relacionado a `.env`/`.env.admin`/keystores antes de confirmar — si la lista se ve limpia:

```bash
git commit -m "test: verificacion manual end-to-end de autenticacion completada" --allow-empty
```

(vacío a propósito si no quedó ningún archivo pendiente — solo deja constancia en el historial de que se verificó.)

---

## Fuera de alcance de este plan (ya documentado en el spec)

- Botón de "Cerrar sesión" en la UI (no hay pantalla de `ajustes` todavía).
- Vinculación explícita Google↔Facebook (`linkIdentity`) — vive en `ajustes`, Fase 2.
- Invitación de barberos por el admin (RPC dedicada) — Fase 2.
- Panel superadmin para crear barberías/promover admins sin SQL manual — Fase 4.
- Pantallas reales de reservas/agenda/dashboard — cada una en su propia funcionalidad más adelante.
