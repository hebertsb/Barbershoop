# Documentación de la Base de Datos — BarberApp (Supabase / PostgreSQL)

> **Ubicación:** `db/BASE_DE_DATOS.md`
> **Motor:** PostgreSQL (Supabase BaaS)
> **Modelo de Negocio:** SaaS Multi-Tenant aislado mediante Row Level Security (RLS) por `barberia_id`.

---

## 1. Visión General del Esquema

La base de datos de BarberApp está diseñada para soportar una arquitectura **multi-tenant** donde cada barbería opera sus datos de manera aislada. Todas las tablas principales incluyen la columna `barberia_id uuid references barberias(id)`.

---

## 2. Diccionario de Tablas y Columnas

### 2.1 `barberias`
Tabla principal de tenants/empresas registradas.
- `id` (uuid, PK): Identificador único de la barbería.
- `nombre` (text, Not Null): Nombre comercial de la barbería.
- `id_licencia` (text): Código o identificador de licencia SaaS.
- `activo` (boolean, Default true): Estado de la suscripción/barbería.
- `creado_en` (timestamptz, Default now()): Fecha de registro.

### 2.2 `sucursales`
Locales físicos pertenecientes a una barbería.
- `id` (uuid, PK): Identificador de la sucursal.
- `barberia_id` (uuid, FK): Referencia a `barberias.id`.
- `nombre` (text, Not Null): Nombre de la sucursal (ej. Central, Equipetrol).
- `direccion` (text): Dirección física.
- `telefono` (text): Teléfono de contacto.
- `activo` (boolean, Default true): Estado operativo.

### 2.3 `perfiles`
Extensión de los usuarios autenticados en Supabase Auth (`auth.users`).
- `id` (uuid, PK): Coincide exactamente con `auth.users.id`.
- `email` (text): Correo electrónico del usuario.
- `nombre` (text, Not Null): Nombre completo.
- `telefono` (text): Teléfono celular.
- `url_foto` (text): URL del avatar o foto de perfil.
- `rol` (text, Enum): Rol del usuario (`cliente`, `barbero`, `secretaria`, `admin`, `superadmin`).
- `barberia_id` (uuid, FK): Barbería a la que pertenece (null para clientes globales).
- `sucursal_id` (uuid, FK): Sucursal asignada (para barberos o secretarias).

### 2.4 `barberos`
Información profesional de los barberos asociados a un perfil.
- `id` (uuid, PK): Identificador del barbero.
- `perfil_id` (uuid, FK): Referencia a `perfiles.id`.
- `barberia_id` (uuid, FK): Referencia a `barberias.id`.
- `sucursal_id` (uuid, FK): Referencia a `sucursales.id`.
- `especialidad` (text): Especialidades del barbero.
- `activo` (boolean, Default true): Estado laboral.

### 2.5 `horarios_barbero`
Disponibilidad semanal por barbero.
- `id` (uuid, PK): Identificador.
- `barbero_id` (uuid, FK): Referencia a `barberos.id`.
- `dia_semana` (int): Día de la semana (1 = Lunes, 7 = Domingo).
- `hora_inicio` (time): Hora de inicio de turno.
- `hora_fin` (time): Hora de fin de turno.

### 2.6 `servicios`
Catálogo de cortes, peinados y tratamientos ofrecidos.
- `id` (uuid, PK): Identificador del servicio.
- `barberia_id` (uuid, FK): Referencia a `barberias.id`.
- `nombre` (text, Not Null): Nombre del servicio.
- `descripcion` (text): Detalles del servicio.
- `precio` (numeric, Not Null): Precio estándar.
- `duracion_minutos` (int, Not Null): Duración estimada.
- `activo` (boolean, Default true): Visibilidad en catálogo.

### 2.7 `citas`
Reservas y agendamiento de clientes.
- `id` (uuid, PK): Identificador de la cita.
- `barberia_id` (uuid, FK): Referencia a `barberias.id`.
- `sucursal_id` (uuid, FK): Referencia a `sucursales.id`.
- `cliente_id` (uuid, FK): Referencia a `perfiles.id`.
- `barbero_id` (uuid, FK): Referencia a `barberos.id`.
- `servicio_id` (uuid, FK): Referencia a `servicios.id`.
- `fecha_hora` (timestamptz, Not Null): Fecha y hora agendada.
- `estado` (text): Estado (`pendiente`, `confirmada`, `en_atencion`, `completada`, `cancelada`).
- `precio_cobrado` (numeric): Monto cobrado al finalizar.
- `notas` (text): Observaciones del cliente o barbero.

### 2.8 `pagos`
Transacciones y comprobantes de transferencias QR manuales.
- `id` (uuid, PK): Identificador del pago.
- `cita_id` (uuid, FK): Cita vinculada.
- `barberia_id` (uuid, FK): Referencia a `barberias.id`.
- `monto` (numeric, Not Null): Monto del pago.
- `metodo` (text): Método (`qr_bancario`, `efectivo`, `tarjeta`).
- `estado` (text): Estado (`pendiente_verificacion`, `aprobado`, `rechazado`).
- `url_comprobante` (text): URL de la captura subida a Supabase Storage.
- `motivo_rechazo` (text): Razón si fue rechazado por el admin.

### 2.9 `clientes_walkin` & `turnos`
Gestión de mostrador y cola presencial sin cita previa.
- `clientes_walkin`: Clientes ocasionales registrados en caja por nombre y teléfono.
- `turnos`: Cola dinámica con estados (`esperando`, `en_atencion`, `completado`, `cancelado`) y número de turno incremental.

### 2.10 `programas_fidelidad` & `progreso_fidelidad`
Tarjetas de fidelización digital con acumulación de sellos/visitas y cortes gratis.

### 2.11 `insumos`, `insumos_barbero` & `reportes_insumo`
Control de inventario, asignación de productos a barberos y reporte de faltantes/bajas.

### 2.12 `promociones` & `usos_promocion`
Cupones de descuento porcentuales o de monto fijo.

### 2.13 `resenas`
Valoraciones de 1 a 5 estrellas y comentarios de clientes al finalizar su cita.

---

## 3. Vistas Curadas para PowerBI

1. `vista_reportes_citas`: Vista unificada con fecha, sucursal, servicio, precio cobrado y estado.
2. `vista_reportes_servicios`: Agregaciones de volumen de servicios demandados e ingresos.
3. `vista_reportes_barberos`: Rendimiento, total de citas e ingresos generados por barbero.

---

## 4. Estructura de Migraciones SQL (`supabase/migraciones/`)

Las 12 migraciones SQL oficiales que construyen esta base de datos en Supabase son:
- `0001_esquema_inicial.sql`
- `0002_rls_multi_tenant.sql`
- `0003_proteger_perfiles.sql`
- `0004_invitar_barbero.sql`
- `0005_permitir_invitar_barbero.sql`
- `0006_atomizar_horarios_barbero.sql`
- `0007_pagos_y_comprobantes.sql`
- `0008_turnos_y_mostrador.sql`
- `0009_fidelidad_e_inventario.sql`
- `0010_ranking_promociones_y_resenas.sql`
- `0011_reportes_y_accesos_admin.sql`
- `0012_vistas_y_rol_powerbi.sql`
