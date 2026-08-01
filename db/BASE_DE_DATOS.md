# Documentación Completa de la Base de Datos — BarberApp (Supabase Live Dump)

> **Ubicación:** `db/BASE_DE_DATOS.md`  
> **Host Real:** `db.jzrfejjtljdfegvcthpm.supabase.co`  
> **Motor:** PostgreSQL 17 (Supabase BaaS)  
> **Modelo de Negocio:** SaaS Multi-Tenant aislado mediante Row Level Security (RLS) por `barberia_id`.

---

## 1. Visión General del Esquema en Vivo

La base de datos viva consta de **22 tablas**, **7 tipos ENUM personalizados**, **69 funciones almacenadas y procedimientos RPC**, y **políticas RLS avanzadas** para garantizar el aislamiento por tenant.

---

## 2. Tipos ENUM Personalizados

1. **`rol_usuario`**: `'cliente'`, `'barbero'`, `'secretaria'`, `'admin'`, `'superadmin'`.
2. **`estado_cita`**: `'pendiente'`, `'confirmada'`, `'en_atencion'`, `'completada'`, `'cancelada'`, `'no_asistio'`.
3. **`estado_pago`**: `'pendiente'`, `'por_verificar'`, `'confirmado'`, `'rechazado'`.
4. **`metodo_pago`**: `'efectivo'`, `'qr_manual'`, `'tarjeta'`.
5. **`estado_turno`**: `'esperando'`, `'en_atencion'`, `'completado'`, `'cancelado'`.
6. **`estado_reporte_insumo`**: `'pendiente'`, `'atendido'`, `'rechazado'`.
7. **`tipo_reporte_insumo`**: `'agotado'`, `'danado'`, `'perdido'`, `'otro'`.

---

## 3. Diccionario Completo de las 22 Tablas

### 3.1 Cuentas, Estructura y Perfiles
- **`barberias`**: Tenants registrados (id, nombre, id_licencia, activo, creado_en).
- **`sucursales`**: Locales físicos (id, barberia_id, nombre, direccion, telefono, activo).
- **`perfiles`**: Extensión de `auth.users` (id, email, nombre, telefono, url_foto, rol, barberia_id, sucursal_id).
- **`barberos`**: Perfiles de barberos (id, perfil_id, barberia_id, sucursal_id, especialidad, activo).
- **`horarios_barbero`**: Matriz semanal (id, barbero_id, dia_semana, hora_inicio, hora_fin).

### 3.2 Operatoria de Servicios y Citas
- **`servicios`**: Catálogo de cortes y tratamientos (id, barberia_id, nombre, descripcion, precio, duracion_minutos, activo).
- **`citas`**: Reservas agendadas (id, barberia_id, sucursal_id, cliente_id, barbero_id, servicio_id, fecha_hora, estado, precio_cobrado, notas).
- **`pagos`**: Transferencias QR y pagos (id, cita_id, barberia_id, monto, metodo, estado, url_comprobante, motivo_rechazo).

### 3.3 Mostrador Presencial & Cola (Walk-in)
- **`clientes_walkin`**: Clientes ocasionales registrados en caja (id, barberia_id, nombre, telefono, creado_en).
- **`turnos`**: Cola en vivo de mostrador (id, barberia_id, sucursal_id, cliente_id, cliente_walkin_id, barbero_id, numero_turno, estado, creado_en).

### 3.4 Fidelización & Recompensas
- **`programas_fidelidad`**: Tarjetas de fidelización (id, barberia_id, titulo, descripcion, citas_requeridas, premio, activo).
- **`progreso_fidelidad`**: Historial de citas acumuladas por cliente (id, programa_id, cliente_id, citas_completadas).
- **`reclamaciones_fidelidad`**: Registro de premios canjeados (id, programa_id, cliente_id, reclamado_en).

### 3.5 Gamificación & Ranking de Barberos
- **`programas_ranking_barberos`**: Configuraciones de temporadas y criterios de ranking por barbería.
- **`insignias_ranking_barberos`**: Medallas y reconocimientos asignados a los mejores barberos.

### 3.6 Inventario & Insumos
- **`insumos`**: Productos de barbería (id, barberia_id, nombre, stock, min_stock, unidad_medida).
- **`insumos_barbero`**: Insumos asignados a cada barbero.
- **`reportes_insumo`**: Alertas y reportes de falta de insumos (id, barbero_id, insumo_id, tipo, cantidad, estado).

### 3.7 Promociones & Reseñas
- **`promociones`**: Descuentos y cupones (id, barberia_id, titulo, descripcion, descuento, codigo, activo).
- **`usos_promocion`**: Historial de cupones canjeados por cliente/cita.
- **`resenas`**: Opiniones y calificaciones de 1 a 5 estrellas (id, barberia_id, cita_id, cliente_id, barbero_id, puntuacion, comentario).

### 3.8 Configuración & Auditoría
- **`configuraciones_barberia`**: Preferencias del SaaS por barbería.
- **`versiones_app`**: Verificación obligatoria de versión mínima de la app Flutter.
- **`accesos_admin_uso`**: Registro de frecuencia de uso de accesos rápidos del panel de administración.

---

## 4. Vistas Curadas para PowerBI

1. `vista_reportes_citas`: Anonymized appointment reporting view.
2. `vista_reportes_servicios`: Aggregated demand and revenue per service.
3. `vista_reportes_barberos`: Performance and revenue metrics per barber.

---

## 5. Resumen de las 69 Funciones RPC Almacenadas

Las funciones incluyen entre otras:
- `invitar_barbero_por_email`
- `reemplazar_horarios_barbero`
- `reservar_cita`
- `confirmar_llegada_cita`
- `subir_comprobante_pago`, `confirmar_pago`, `rechazar_pago`
- `crear_turno_walkin`, `crear_turno_con_cuenta`, `llamar_turno`, `completar_turno`, `cancelar_turno`
- `obtener_progreso_fidelidad_cliente`, `reclamar_premio_fidelidad`
- `validar_promocion`, `obtener_ranking_barberos`, `obtener_mi_ranking_barbero`
- `crear_resena`, `obtener_mis_resenas`
- `obtener_resumen_ingresos`, `obtener_tendencia_ingresos`, `obtener_reporte_top_servicios`, `obtener_reporte_retencion_clientes`
