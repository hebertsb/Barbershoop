-- ============================================================================
-- BarberApp - Esquema inicial multi-tenant
-- ============================================================================

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- Tipos enumerados
-- ----------------------------------------------------------------------------

create type rol_usuario as enum ('cliente', 'barbero', 'admin', 'superadmin');

create type estado_cita as enum (
  'pendiente',
  'confirmada',
  'completada',
  'cancelada',
  'no_asistio'
);

create type metodo_pago as enum ('efectivo', 'qr_manual', 'pasarela');

create type estado_pago as enum ('pendiente', 'por_verificar', 'confirmado', 'rechazado');

create type tipo_reporte_insumo as enum ('danado', 'agotado', 'perdido');

create type estado_reporte_insumo as enum ('pendiente', 'atendido', 'rechazado');

-- ----------------------------------------------------------------------------
-- Función utilitaria: actualizar columna actualizado_en
-- ----------------------------------------------------------------------------

create or replace function actualizar_columna_actualizado_en()
returns trigger as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$ language plpgsql;

-- ----------------------------------------------------------------------------
-- barberias (tenant raíz)
-- ----------------------------------------------------------------------------

create table barberias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  slogan text,
  url_logo text,
  plan_saas text not null default 'basico',
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create trigger trg_barberias_actualizado_en
  before update on barberias
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- sucursales
-- ----------------------------------------------------------------------------

create table sucursales (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  nombre text not null,
  direccion text,
  telefono text,
  horario_apertura time,
  horario_cierre time,
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_sucursales_barberia on sucursales(barberia_id);

create trigger trg_sucursales_actualizado_en
  before update on sucursales
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- perfiles (1:1 con auth.users)
-- ----------------------------------------------------------------------------

create table perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  barberia_id uuid references barberias(id) on delete set null,
  rol rol_usuario not null default 'cliente',
  nombre text,
  url_foto text,
  telefono text,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_perfiles_barberia on perfiles(barberia_id);

create trigger trg_perfiles_actualizado_en
  before update on perfiles
  for each row execute function actualizar_columna_actualizado_en();

-- Trigger: crear perfil automáticamente al registrarse en auth.users
create or replace function manejar_nuevo_usuario()
returns trigger as $$
begin
  insert into public.perfiles (id, nombre, url_foto)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trg_auth_nuevo_usuario
  after insert on auth.users
  for each row execute function manejar_nuevo_usuario();

-- ----------------------------------------------------------------------------
-- barberos
-- ----------------------------------------------------------------------------

create table barberos (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references perfiles(id) on delete cascade,
  sucursal_id uuid not null references sucursales(id) on delete cascade,
  barberia_id uuid not null references barberias(id) on delete cascade,
  especialidades text[],
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  unique (perfil_id, sucursal_id)
);

create index idx_barberos_barberia on barberos(barberia_id);
create index idx_barberos_sucursal on barberos(sucursal_id);

create trigger trg_barberos_actualizado_en
  before update on barberos
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- horarios_barbero
-- ----------------------------------------------------------------------------

create table horarios_barbero (
  id uuid primary key default gen_random_uuid(),
  barbero_id uuid not null references barberos(id) on delete cascade,
  barberia_id uuid not null references barberias(id) on delete cascade,
  dia_semana smallint not null check (dia_semana between 0 and 6),
  hora_inicio time not null,
  hora_fin time not null,
  creado_en timestamptz not null default now(),
  check (hora_fin > hora_inicio)
);

create index idx_horarios_barbero on horarios_barbero(barbero_id);

-- ----------------------------------------------------------------------------
-- servicios
-- ----------------------------------------------------------------------------

create table servicios (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  nombre text not null,
  descripcion text,
  duracion_min integer not null check (duracion_min > 0),
  precio numeric(10, 2) not null check (precio >= 0),
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_servicios_barberia on servicios(barberia_id);

create trigger trg_servicios_actualizado_en
  before update on servicios
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- citas (núcleo del sistema)
-- ----------------------------------------------------------------------------

create table citas (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  sucursal_id uuid not null references sucursales(id) on delete cascade,
  barbero_id uuid not null references barberos(id) on delete cascade,
  cliente_id uuid not null references perfiles(id) on delete cascade,
  servicio_id uuid not null references servicios(id) on delete restrict,
  fecha_hora timestamptz not null,
  duracion_min integer not null check (duracion_min > 0),
  estado estado_cita not null default 'pendiente',
  precio_cobrado numeric(10, 2),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  -- Evita doble reserva exacta del mismo barbero a la misma hora.
  unique (barbero_id, fecha_hora)
);

create index idx_citas_barberia on citas(barberia_id);
create index idx_citas_barbero_fecha on citas(barbero_id, fecha_hora);
create index idx_citas_cliente on citas(cliente_id);

create trigger trg_citas_actualizado_en
  before update on citas
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- pagos
-- ----------------------------------------------------------------------------

create table pagos (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  cita_id uuid not null references citas(id) on delete cascade,
  monto numeric(10, 2) not null check (monto >= 0),
  metodo metodo_pago not null default 'qr_manual',
  estado estado_pago not null default 'pendiente',
  url_comprobante text,
  verificado_por uuid references perfiles(id) on delete set null,
  fecha timestamptz not null default now(),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_pagos_barberia on pagos(barberia_id);
create index idx_pagos_cita on pagos(cita_id);

create trigger trg_pagos_actualizado_en
  before update on pagos
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- insumos (almacén por sucursal)
-- ----------------------------------------------------------------------------

create table insumos (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  sucursal_id uuid not null references sucursales(id) on delete cascade,
  nombre text not null,
  categoria text,
  stock integer not null default 0 check (stock >= 0),
  stock_minimo integer not null default 0 check (stock_minimo >= 0),
  costo_unitario numeric(10, 2),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_insumos_barberia on insumos(barberia_id);
create index idx_insumos_sucursal on insumos(sucursal_id);

create trigger trg_insumos_actualizado_en
  before update on insumos
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- insumos_barbero
-- ----------------------------------------------------------------------------

create table insumos_barbero (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  barbero_id uuid not null references barberos(id) on delete cascade,
  insumo_id uuid not null references insumos(id) on delete cascade,
  cantidad_asignada integer not null default 0 check (cantidad_asignada >= 0),
  creado_en timestamptz not null default now(),
  unique (barbero_id, insumo_id)
);

create index idx_insumos_barbero_barberia on insumos_barbero(barberia_id);

-- ----------------------------------------------------------------------------
-- reportes_insumo
-- ----------------------------------------------------------------------------

create table reportes_insumo (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  barbero_id uuid not null references barberos(id) on delete cascade,
  insumo_id uuid not null references insumos(id) on delete cascade,
  tipo tipo_reporte_insumo not null,
  descripcion text,
  url_foto text,
  estado estado_reporte_insumo not null default 'pendiente',
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_reportes_insumo_barberia on reportes_insumo(barberia_id);

create trigger trg_reportes_insumo_actualizado_en
  before update on reportes_insumo
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- promociones
-- ----------------------------------------------------------------------------

create table promociones (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  titulo text not null,
  descripcion text,
  imagen text,
  descuento numeric(5, 2),
  fecha_inicio date,
  fecha_fin date,
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index idx_promociones_barberia on promociones(barberia_id);

create trigger trg_promociones_actualizado_en
  before update on promociones
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- configuraciones_barberia (clave-valor, extensibilidad sin migraciones)
-- ----------------------------------------------------------------------------

create table configuraciones_barberia (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  clave text not null,
  valor jsonb not null default '{}'::jsonb,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  unique (barberia_id, clave)
);

create index idx_configuraciones_barberia on configuraciones_barberia(barberia_id);

create trigger trg_configuraciones_barberia_actualizado_en
  before update on configuraciones_barberia
  for each row execute function actualizar_columna_actualizado_en();

-- ----------------------------------------------------------------------------
-- versiones_app (auto-verificación de versión)
-- ----------------------------------------------------------------------------

create table versiones_app (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  url_apk text not null,
  notas_cambios text,
  obligatoria boolean not null default false,
  fecha timestamptz not null default now()
);
