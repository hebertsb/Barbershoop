# Plan de Proyecto: App SaaS para Barberías (Flutter)

> Documento de planificación para desarrollar con Claude Code. Nombre provisional: **BarberApp** (cámbialo por tu marca). Guardar como `PLAN.md` en la raíz del repositorio.

---

## 1. Visión general

Una app móvil multiplataforma (Android primero) con tres experiencias en una sola app según el rol:

- **Cliente**: reserva citas sin ir a la barbería (sucursal → servicio → barbero → horario), paga por QR, ve promociones y eventos.
- **Barbero**: su agenda, marca citas completadas, gestiona y reporta sus insumos.
- **Dueño/Admin**: citas, sucursales, barberos, servicios, inventario, promociones, ajustes de la barbería y reportes de ingresos (día/mes/año).

Modelo de negocio: **SaaS multi-tenant** — una sola infraestructura que sirve a muchas barberías con datos aislados.

### Estrategia de lanzamiento definida

1. **Primer cliente: una sola barbería**, pero arquitectura **multi-tenant desde el día uno** (`barberia_id` + RLS en todas las tablas). Agregar esto al inicio cuesta casi nada; agregarlo después con datos en producción es doloroso.
2. **Distribución sin Play Store**: APK firmado + landing de descarga + **código QR en el local** ("Escanea y reserva tu cita"). Cero costo de publicación.
3. **Auto-verificación de versión** dentro de la app (obligatoria en el MVP).
4. **Pagos**: primero QR bancario manual con comprobante (costo $0); pasarela automatizada como mejora futura.
5. **A futuro**: con 2+ barberías se activa el modo SaaS (panel superadmin, suscripciones) y se evalúa Play Store ($25 único). iOS ($99/año) solo cuando los ingresos lo justifiquen.

---

## 2. Decisión clave: ¿Google Sheets como base de datos? NO — usa Supabase

Sheets no sirve para un SaaS: sin transacciones (citas duplicadas), límites de API (~300 lecturas/min), sin aislamiento seguro entre barberías, sin tiempo real y se degrada con volumen.

### Elegido: **Supabase** (costo $0 para empezar)

- **PostgreSQL real** con plan gratuito generoso (500 MB de DB, 50k usuarios de auth/mes).
- **Auth con Google y Facebook incluido** — el login simple deseado, sin programarlo.
- **Row Level Security (RLS)**: aislamiento multi-tenant por `barberia_id`.
- **Realtime**: horarios disponibles actualizados al instante.
- **Conexión nativa a Power BI** por ser PostgreSQL.
- SDK oficial de Flutter (`supabase_flutter`).

---

## 3. Arquitectura: sin backend propio

**Lenguaje: Dart (Flutter) para toda la app.** No se escribe ni mantiene un servidor propio: Supabase actúa como Backend-as-a-Service (auth, base de datos, storage de imágenes, funciones). Esto es lo que hace posible el costo mínimo.

```
┌─────────────────────────────────────────┐
│           App Flutter (una sola)         │
│   Cliente   │   Barbero   │    Admin     │  ← vistas según rol
└───────────────────┬─────────────────────┘
                    │ supabase_flutter SDK
┌───────────────────▼─────────────────────┐
│               Supabase                   │
│  Auth (Google/Facebook) · PostgreSQL     │
│  RLS multi-tenant · Storage (fotos/QR)   │
│  Funciones SQL · Edge Functions          │
└───────────────────┬─────────────────────┘
                    │ conexión PostgreSQL
              ┌─────▼─────┐
              │  Power BI │
              └───────────┘
```

La lógica "de servidor" vive en dos lugares dentro de Supabase:

1. **Funciones SQL (PostgreSQL)**: lógica crítica pegada a los datos. Ej.: `obtener_horarios_disponibles()` — el cálculo de horarios se hace en la DB, no en el teléfono, para evitar dobles reservas. También las políticas RLS.
2. **Edge Functions (TypeScript)**: solo para servicios externos — enviar push al crear una cita y, a futuro, el webhook de la pasarela de pagos. Son 2-3 funciones de ~50 líneas.

¿Cuándo haría falta backend propio? Solo con integraciones muy pesadas a futuro; ese día se agrega un servicio pequeño aparte sin tocar lo construido.

- Gestión de estado: **Riverpod**. Navegación: **go_router**.

---

## 4. Estructura del proyecto (3 capas, en español)

Organización **por funcionalidades (features)**, y dentro de cada una, **3 capas**: `datos` / `dominio` / `presentacion`. La vista nunca contiene lógica; la lógica nunca dibuja pantalla.

```
barber_app/
├── lib/
│   ├── main.dart
│   ├── nucleo/                          # Lo compartido por toda la app
│   │   ├── configuracion/               # cliente_supabase.dart, constantes.dart, tema_app.dart
│   │   ├── enrutador/                   # enrutador_app.dart (go_router + redirección por rol)
│   │   ├── componentes/                 # Reutilizables globales: boton_primario.dart,
│   │   │                                #   campo_texto.dart, dialogo_confirmacion.dart,
│   │   │                                #   indicador_carga.dart, tarjeta_base.dart
│   │   ├── utilidades/                  # formato_fecha.dart, formato_moneda.dart, validadores.dart
│   │   └── errores/                     # excepciones_app.dart, manejador_errores.dart
│   │
│   ├── funcionalidades/
│   │   ├── autenticacion/
│   │   │   ├── datos/                   #   repositorio_autenticacion.dart
│   │   │   ├── dominio/                 #   modelo_perfil.dart, enum_rol_usuario.dart
│   │   │   └── presentacion/
│   │   │       ├── pantallas/           #   pantalla_inicio_sesion.dart, pantalla_seleccion_rol.dart
│   │   │       ├── controladores/       #   controlador_autenticacion.dart (Riverpod)
│   │   │       └── componentes/         #   boton_google.dart, encabezado_bienvenida.dart
│   │   │
│   │   ├── reservas/                    # Flujo de reserva del cliente
│   │   │   ├── datos/                   #   repositorio_reservas.dart
│   │   │   ├── dominio/                 #   modelo_cita.dart, modelo_horario_disponible.dart
│   │   │   └── presentacion/
│   │   │       ├── pantallas/           #   pantalla_seleccion_sucursal.dart,
│   │   │       │                        #   pantalla_seleccion_servicio.dart,
│   │   │       │                        #   pantalla_seleccion_barbero.dart,
│   │   │       │                        #   pantalla_seleccion_horario.dart,
│   │   │       │                        #   pantalla_confirmacion_reserva.dart
│   │   │       ├── controladores/       #   controlador_reserva.dart
│   │   │       └── componentes/         #   tarjeta_servicio.dart, tarjeta_barbero.dart,
│   │   │                                #   selector_horario.dart, resumen_reserva.dart
│   │   │
│   │   ├── citas/                       # Agenda (barbero/admin), walk-in, estados
│   │   │   ├── datos/                   #   repositorio_citas.dart
│   │   │   ├── dominio/                 #   enum_estado_cita.dart
│   │   │   └── presentacion/
│   │   │       ├── pantallas/           #   pantalla_agenda_barbero.dart, pantalla_citas_dia.dart,
│   │   │       │                        #   pantalla_registro_walk_in.dart
│   │   │       ├── controladores/       #   controlador_agenda.dart
│   │   │       └── componentes/         #   tarjeta_cita.dart, etiqueta_estado.dart
│   │   │
│   │   ├── pagos/
│   │   │   ├── datos/                   #   repositorio_pagos.dart
│   │   │   ├── dominio/                 #   modelo_pago.dart, enum_metodo_pago.dart,
│   │   │   │                            #   enum_estado_pago.dart
│   │   │   └── presentacion/
│   │   │       ├── pantallas/           #   pantalla_pago_qr.dart, pantalla_subir_comprobante.dart,
│   │   │       │                        #   pantalla_verificacion_pagos.dart (admin)
│   │   │       ├── controladores/       #   controlador_pagos.dart
│   │   │       └── componentes/         #   visor_qr_banco.dart, tarjeta_comprobante.dart
│   │   │
│   │   ├── administracion/              # Dashboard, sucursales, barberos, servicios
│   │   │   ├── datos/                   #   repositorio_administracion.dart
│   │   │   ├── dominio/                 #   modelo_sucursal.dart, modelo_barbero.dart,
│   │   │   │                            #   modelo_servicio.dart
│   │   │   └── presentacion/
│   │   │       ├── pantallas/           #   pantalla_dashboard.dart, pantalla_sucursales.dart,
│   │   │       │                        #   pantalla_barberos.dart, pantalla_servicios.dart
│   │   │       ├── controladores/       #   controlador_dashboard.dart, controlador_servicios.dart
│   │   │       └── componentes/         #   tarjeta_ingresos.dart, grafico_citas.dart,
│   │   │                                #   formulario_servicio.dart
│   │   │
│   │   ├── inventario/
│   │   │   ├── datos/                   #   repositorio_inventario.dart
│   │   │   ├── dominio/                 #   modelo_insumo.dart, modelo_reporte_insumo.dart
│   │   │   └── presentacion/
│   │   │       ├── pantallas/           #   pantalla_almacen.dart, pantalla_mis_insumos.dart,
│   │   │       │                        #   pantalla_reportar_insumo.dart,
│   │   │       │                        #   pantalla_bandeja_reportes.dart (admin)
│   │   │       ├── controladores/       #   controlador_inventario.dart
│   │   │       └── componentes/         #   tarjeta_insumo.dart, alerta_stock_minimo.dart
│   │   │
│   │   ├── reportes/                    # Ingresos día/mes/año, clientes frecuentes
│   │   ├── promociones/                 # Promos y eventos
│   │   ├── ajustes/                     # Slogan, logo, tema, QR del banco, config de pagos
│   │   └── actualizacion_app/           # Auto-verificación de versión
│   │       (todas con la misma estructura datos/dominio/presentacion)
│   │
├── supabase/
│   ├── migraciones/                     # Esquema SQL versionado (¡vive en el repo!)
│   └── funciones/                       # Edge Functions (notificaciones, webhook de pagos)
├── CLAUDE.md                            # Convenciones para Claude Code
└── PLAN.md                              # Este documento
```

### Responsabilidad de cada capa

| Capa | Qué hace | Qué NO hace |
|---|---|---|
| `dominio/` | Modelos y enums puros (Cita, Insumo, EstadoPago). Sin dependencias de Flutter ni Supabase. | No dibuja, no consulta datos |
| `datos/` | Repositorios: única capa que habla con Supabase. Reciben/devuelven modelos del dominio. | No contiene lógica de UI ni estado |
| `presentacion/pantallas/` | Solo estructura visual. Lee estado del controlador y dispara sus métodos. | Cero lógica de negocio, cero llamadas a Supabase |
| `presentacion/controladores/` | Estado y lógica de la pantalla (Riverpod Notifier). Llama a los repositorios. | No construye widgets |
| `presentacion/componentes/` | Widgets pequeños y reutilizables de esa funcionalidad. | No manejan estado global |

### Convenciones de código (van también en CLAUDE.md)

- **Todo en español**: archivos, clases, funciones, variables y comentarios. Ej.: `class RepositorioCitas`, `Future<List<Cita>> obtenerCitasDelDia()`, `void confirmarPago()`. *Excepción honesta*: las palabras clave de Dart/Flutter y las APIs de paquetes son en inglés (`build`, `initState`, `Widget`) — eso no se traduce; lo nuestro sí.
- **Archivos cortos**: máximo ~250-300 líneas. Si una pantalla crece, se extraen componentes a `componentes/`. Nunca archivos de 600-1000 líneas.
- **Una clase pública por archivo**, nombre de archivo = nombre de clase en snake_case (`controlador_reserva.dart` → `ControladorReserva`).
- **La vista nunca llama a Supabase directo**: pantalla → controlador → repositorio → Supabase. Siempre.
- Modelos inmutables con `copyWith`, `desdeJson`/`aJson`.
- Manejo de errores centralizado en `nucleo/errores/`; los repositorios lanzan excepciones propias (`ExcepcionRed`, `ExcepcionPermiso`) y los controladores las traducen a mensajes para el usuario.
- Formato con `dart format` y análisis con `flutter_lints` activado.

---

## 5. Modelo de datos (tablas principales)

| Tabla | Campos clave | Notas |
|---|---|---|
| `barberias` | id, nombre, slogan, url_logo, plan_saas, activo | Cada tenant |
| `sucursales` | id, barberia_id, nombre, dirección, teléfono, horario | Si hay una sola, se crea por defecto |
| `perfiles` | id (= auth.uid), rol (cliente/barbero/admin/superadmin), nombre, foto, teléfono, barberia_id | Se crea automático al registrarse con Google |
| `barberos` | id, perfil_id, sucursal_id, especialidades, activo | |
| `horarios_barbero` | barbero_id, día_semana, hora_inicio, hora_fin | Disponibilidad base |
| `servicios` | id, barberia_id, nombre, descripción, duración_min, precio, activo | Corte, pigmentación y **cualquier servicio nuevo sin tocar código** |
| `citas` | id, sucursal_id, barbero_id, cliente_id, servicio_id, fecha_hora, estado (pendiente/confirmada/completada/cancelada/no_asistio), precio_cobrado | Núcleo del sistema |
| `pagos` | id, cita_id, monto, **metodo** (efectivo/qr_manual/pasarela), **estado** (pendiente/por_verificar/confirmado/rechazado), url_comprobante, verificado_por, fecha | Diseñada para sumar pasarela sin migrar nada |
| `insumos` | id, sucursal_id, nombre, categoría, stock, stock_mínimo, costo_unitario | Almacén por sucursal |
| `insumos_barbero` | barbero_id, insumo_id, cantidad_asignada | Insumos de cada barbero |
| `reportes_insumo` | id, barbero_id, insumo_id, tipo (dañado/agotado/perdido), descripción, url_foto, estado | Avisos al admin |
| `promociones` | id, barberia_id, título, descripción, imagen, descuento, fecha_inicio/fin, activo | Promos y eventos |
| `configuraciones_barberia` | barberia_id, clave, valor | **Clave para extensibilidad**: modo_pago (obligatorio/opcional/seña), porcentaje_seña, url_qr_banco, colores, y cualquier ajuste futuro sin migraciones |
| `versiones_app` | id, versión, url_apk, notas_cambios, obligatoria, fecha | Auto-verificación de versión |

**Vistas SQL para reportes** (ingresos por día/mes/año, citas por barbero, clientes frecuentes, servicios más pedidos) — Power BI las consume directo.

---

## 6. Módulo de pagos

### Etapa A — QR bancario manual con comprobante (MVP de pagos, costo $0)

1. El admin sube desde **Ajustes** la imagen del QR de su banco (QR Simple de su banca móvil) y la actualiza cuando quiera (resuelve la renovación periódica).
2. Configura el modo: pago **obligatorio**, **opcional** o **solo seña** (% configurable) — argumento de venta: cada dueño elige.
3. Al reservar, el cliente ve el QR con el monto, paga desde su banca y **sube la captura del comprobante**.
4. La cita queda "pago por verificar"; el admin recibe notificación, revisa su banca y confirma con un toque → cita "confirmada".
5. Beneficio extra: el que paga seña, llega — reduce no-shows.

### Etapa B — Pasarela automatizada (fase SaaS)

- Opciones en Bolivia: pasarelas (Libélula, PagosNet, Veripagos) o APIs de QR dinámico de bancos (BNB, BancoSol, etc.).
- Requiere contrato de cada barbería con la pasarela y comisión por transacción (~2-5%).
- Técnicamente: una Edge Function como **webhook** que recibe la confirmación del banco y marca el pago como confirmado. Se agrega como un `metodo` más en la tabla `pagos` — **cero reestructuración**.

---

## 7. Funcionalidades por rol

### Cliente
- Login con Google (Facebook opcional) en un toque.
- Explorar: sucursales, servicios con precio y duración, promociones/eventos.
- Reserva: sucursal → servicio → barbero disponible (o "cualquiera") → horarios libres en tiempo real → pago QR (según config) → confirmación.
- Ver/cancelar/reprogramar citas; historial.
- Push: recordatorio 24 h y 1 h antes. El cliente solo llega a su hora.

### Barbero
- Agenda día/semana; marcar completada / no asistió (registra el ingreso).
- Sus insumos asignados; **reportar dañado/agotado con foto** → notifica al admin.

### Admin/Dueño
- **Dashboard**: ingresos hoy/mes/año, citas del día, barberos activos, gráficos.
- Sucursales, barberos (invitación por correo/link), horarios.
- Servicios: crear/editar cualquiera (pigmentación, etc.) con precio y duración.
- **Walk-in**: registrar cita presencial.
- Inventario: stock por sucursal, asignación a barberos, alertas de stock mínimo, bandeja de reportes.
- **Verificación de pagos QR**.
- **Ajustes**: nombre, slogan, logo, tema/colores, QR del banco, modo de pago, horarios; promociones y eventos.
- Reportes de clientes: frecuencia, ranking, últimos servicios.

### Superadmin (tú, dueño del SaaS)
- Alta/baja de barberías, plan y estado de suscripción.

---

## 8. Principios de extensibilidad (crecer sin reestructurar)

Diseño pensado para que toda mejora futura sea **agregar, no rehacer**:

1. **Multi-tenant desde el día 1**: pasar de 1 barbería a N no toca ni una tabla.
2. **`configuraciones_barberia` (clave-valor)**: cualquier ajuste nuevo (un color, una regla, un flag) se agrega sin migración ni release.
3. **Servicios como datos, no como código**: ofrecer "pigmentación" o lo que sea = insertar una fila.
4. **`pagos.metodo` extensible**: efectivo → QR manual → pasarela → lo que venga, misma tabla.
5. **Estados como enums en el dominio**: agregar un estado de cita nuevo toca 1 enum + 1 etiqueta, no 20 archivos.
6. **Repositorios como frontera**: si mañana se cambia Supabase por otro backend, solo se reescriben los repositorios; dominio y pantallas intactos.
7. **3 capas estrictas**: cualquier feature nueva se agrega como carpeta nueva en `funcionalidades/` sin tocar las existentes.
8. **Migraciones SQL versionadas en el repo**: la DB evoluciona con historial, junto al código.
9. **Feature flags por barbería**: funciones premium del SaaS (Power BI, multi-sucursal) se activan por configuración según el plan contratado.
10. **`versiones_app` con actualización obligatoria**: permite forzar migraciones de app cuando un cambio lo requiera.

---

## 9. Distribución sin Play Store (APK + QR + auto-actualización)

### Flujo
1. APK firmado: `flutter build apk --release` (crear keystore propio y **respaldarlo en 2+ lugares** — sin él no hay actualizaciones instalables).
2. Subir el APK a **Supabase Storage** (bucket público `releases/`) o GitHub Releases.
3. **Landing de descarga** gratuita (Netlify/Vercel/GitHub Pages): logo, descripción, botón "Descargar app" e instrucciones del aviso de "origen desconocido".
4. **Código QR** hacia la landing, impreso en el mostrador: *"Escanea y reserva tu cita"*. También para Instagram/WhatsApp.

### Auto-verificación de versión (en el MVP)
- Al abrir, comparar versión instalada (`package_info_plus`) contra `versiones_app`.
- Si hay nueva: diálogo con link de descarga; si `obligatoria` = true, bloquear hasta actualizar.
- Paquete `upgrader` o lógica propia (~30 líneas).

### Limitaciones a comunicar
- **Solo Android** (iPhone requiere App Store, $99/año — queda para la fase SaaS).
- El aviso de "origen desconocido" sale una vez; el QR en el local elimina la desconfianza.

---

## 10. Estrategia de costos mínimos

| Recurso | Costo inicial | Cuándo pagar |
|---|---|---|
| Supabase | $0 (free tier) | ~$25/mes al superar límites (varias barberías) |
| Push (FCM) | $0 siempre | — |
| Distribución (Storage + landing + QR) | $0 | — |
| Google Play | $0 al inicio | $25 único, recién en fase SaaS |
| App Store (iOS) | $0 al inicio | $99/año solo si los ingresos lo justifican |
| Pagos QR manual | $0 | Pasarela con comisión ~2-5%, solo en fase SaaS |
| Dominio + landing propia | ~$10/año | Opcional, para vender con marca |

**Modelos de venta**: (a) llave en mano $800-2,500; (b) venta + mantenimiento $10-30/mes; (c) alquiler mensual $25-50/mes. Recomendado: (b) o (c) con el primer cliente como caso de éxito. SaaS: básico ~$15-25/mes, pro ~$40-60/mes — con 2 suscripciones se cubre toda la infraestructura.

---

## 11. Plan de implementación por fases (para ejecutar con Claude Code)

### Fase 0 — Preparación (1-2 días)
- Proyecto en Supabase + Google OAuth (Facebook opcional).
- `flutter create barber_app` con la estructura de 3 capas en español.
- Esquema SQL completo + RLS multi-tenant (generado con Claude Code) en `supabase/migraciones/`.
- Redactar `CLAUDE.md` con las convenciones de la sección 4.

### Fase 1 — MVP (3-4 semanas) ✂️
1. Auth con Google + creación automática de perfil + enrutamiento por rol.
2. Onboarding del admin: barbería, sucursal, servicios, barberos y horarios.
3. Flujo completo de reserva (función SQL `obtener_horarios_disponibles` según duración del servicio y agenda).
4. Agenda del barbero + marcar completada (registra ingreso).
5. Dashboard básico: ingresos día/mes, citas de hoy.
6. Walk-in.
7. **Auto-verificación de versión**.
8. **Lanzamiento**: APK firmado en Storage, landing y QR impreso.

### Fase 2 — Operación completa (2-3 semanas)
9. Push (recordatorios, aviso de nueva cita al barbero).
10. **Pagos Etapa A**: QR del banco en Ajustes, modos de pago, subida de comprobante, bandeja de verificación.
11. Inventario completo: insumos, asignaciones, reportes con foto, alertas de stock.
12. Ajustes: slogan, logo, tema; promociones y eventos.
13. Cancelación/reprogramación con reglas (ej. mínimo 2 h antes).

### Fase 3 — Reportes (2 semanas)
14. Reportes en app: ingresos anuales, por barbero/servicio/sucursal; clientes frecuentes.
15. Vistas SQL + guía de conexión Power BI (usuario de solo lectura por barbería).

### Fase 4 — Activación del modo SaaS (con 2+ barberías interesadas)
16. Panel superadmin + suscripciones (manual al inicio). La base multi-tenant ya existe: solo se construye la capa de gestión.
17. Onboarding self-service para barberías nuevas.
18. **Pagos Etapa B**: pasarela con webhook (Edge Function).
19. Publicación en Google Play ($25 único).
20. Feature flags por plan (básico/pro).

### Fase 5 — Backlog de mejoras futuras
- Programa de fidelidad (corte n.º 10 gratis) y cupones.
- Reseñas y calificación de barberos.
- Lista de espera cuando no hay horarios.
- App web (Flutter Web) para gestionar desde PC.
- Multi-idioma.
- IA: horarios óptimos, predicción de no-shows, sugerencia de compra de insumos.
- Facturación automática del SaaS (Stripe Billing).

---

## 12. Cómo trabajar esto con Claude Code

Tareas sugeridas (una sesión por punto):

1. "Genera el esquema SQL de Supabase con todas las tablas del plan (nombres en español), políticas RLS multi-tenant por `barberia_id` y trigger de creación de perfil al registrarse."
2. "Crea el proyecto Flutter con Riverpod + go_router + supabase_flutter, con la estructura de 3 capas en español del PLAN.md (sección 4) y las convenciones del CLAUDE.md."
3. "Implementa la funcionalidad `autenticacion` completa: login con Google y enrutamiento por rol, respetando pantalla → controlador → repositorio."
4. "Implementa `reservas`: función SQL `obtener_horarios_disponibles(barbero_id, fecha, servicio_id)` y sus pantallas."
5. …y así con cada punto de las fases.

Consejos:
- Mantener `PLAN.md` y `CLAUDE.md` en la raíz: Claude Code los lee como contexto.
- Pedir **tests** para la lógica de horarios disponibles (lo más delicado).
- Commits por funcionalidad para poder retroceder.
- Recordarle en CLAUDE.md: archivos máx. ~300 líneas, extraer componentes, nada de lógica en las pantallas.

---

## 13. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Doble reserva del mismo horario | Constraint único (barbero_id + fecha_hora) + transacción en la función SQL |
| Internet inestable en el local | Caché local y reintentos |
| No-shows | Estado "no asistió" + seña por QR (la Etapa A ya lo reduce) |
| Comprobantes de pago falsos | El admin verifica contra su banca antes de confirmar; a futuro, pasarela automática |
| Usuarios con APK viejo | Auto-verificación con actualización obligatoria |
| Pérdida del keystore | Respaldo en 2+ lugares seguros |
| Clientes con iPhone | Comunicarlo desde el inicio; App Store en fase SaaS |
| Superar el free tier | Migración transparente al plan Pro de Supabase; el precio del SaaS lo cubre |
