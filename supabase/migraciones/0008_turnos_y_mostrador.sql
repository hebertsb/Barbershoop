-- ============================================================================
-- BarberApp - Migración 0008: Turnos de Mostrador (Walk-in) y Cola
-- ============================================================================

-- ----------------------------------------------------------------------------
-- clientes_walkin (Clientes sin cuenta registrada en app)
-- ----------------------------------------------------------------------------

create table if not exists clientes_walkin (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  sucursal_id uuid not null references sucursales(id) on delete cascade,
  nombre text not null,
  telefono text,
  creado_en timestamptz not null default now()
);

alter table clientes_walkin enable row level security;

create policy clientes_walkin_select on clientes_walkin
  for select using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

create policy clientes_walkin_insert on clientes_walkin
  for insert with check (
    barberia_id = obtener_barberia_id_actual()
  );

-- ----------------------------------------------------------------------------
-- turnos (Cola presencial del día)
-- ----------------------------------------------------------------------------

create table if not exists turnos (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  sucursal_id uuid not null references sucursales(id) on delete cascade,
  numero int not null,
  cliente_id uuid references perfiles(id) on delete cascade,
  cliente_walkin_id uuid references clientes_walkin(id) on delete cascade,
  servicio_id uuid not null references servicios(id) on delete cascade,
  barbero_id uuid references barberos(id) on delete set null,
  estado text not null default 'esperando' check (estado in ('esperando', 'en_atencion', 'completado', 'cancelado')),
  cita_id uuid references citas(id) on delete set null,
  hora_llegada timestamptz not null default now(),
  hora_atencion timestamptz,
  hora_completado timestamptz,
  monto_precobrado numeric,
  metodo_precobrado text,
  actualizado_en timestamptz not null default now()
);

alter table turnos enable row level security;

create policy turnos_select on turnos
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy turnos_escritura on turnos
  for all using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

-- ----------------------------------------------------------------------------
-- Funciones de Gestión de Turnos
-- ----------------------------------------------------------------------------

create or replace function crear_turno_walkin(
  p_sucursal_id uuid,
  p_servicio_id uuid,
  p_nombre text,
  p_telefono text default null,
  p_monto_precobrado numeric default null,
  p_metodo_precobrado text default null
)
returns uuid as $$
declare
  v_barberia_id uuid;
  v_walkin_id uuid;
  v_siguiente_numero int;
  v_turno_id uuid;
begin
  select barberia_id into v_barberia_id from sucursales where id = p_sucursal_id;

  insert into clientes_walkin (barberia_id, sucursal_id, nombre, telefono)
  values (v_barberia_id, p_sucursal_id, p_nombre, p_telefono)
  returning id into v_walkin_id;

  select coalesce(max(numero), 0) + 1 into v_siguiente_numero
  from turnos
  where sucursal_id = p_sucursal_id
    and hora_llegada::date = current_date;

  insert into turnos (
    barberia_id,
    sucursal_id,
    numero,
    cliente_walkin_id,
    servicio_id,
    estado,
    monto_precobrado,
    metodo_precobrado
  ) values (
    v_barberia_id,
    p_sucursal_id,
    v_siguiente_numero,
    v_walkin_id,
    p_servicio_id,
    'esperando',
    p_monto_precobrado,
    p_metodo_precobrado
  )
  returning id into v_turno_id;

  return v_turno_id;
end;
$$ language plpgsql security definer;

create or replace function crear_turno_con_cuenta(
  p_sucursal_id uuid,
  p_servicio_id uuid,
  p_cliente_id uuid,
  p_monto_precobrado numeric default null,
  p_metodo_precobrado text default null
)
returns uuid as $$
declare
  v_barberia_id uuid;
  v_siguiente_numero int;
  v_turno_id uuid;
begin
  select barberia_id into v_barberia_id from sucursales where id = p_sucursal_id;

  select coalesce(max(numero), 0) + 1 into v_siguiente_numero
  from turnos
  where sucursal_id = p_sucursal_id
    and hora_llegada::date = current_date;

  insert into turnos (
    barberia_id,
    sucursal_id,
    numero,
    cliente_id,
    servicio_id,
    estado,
    monto_precobrado,
    metodo_precobrado
  ) values (
    v_barberia_id,
    p_sucursal_id,
    v_siguiente_numero,
    p_cliente_id,
    p_servicio_id,
    'esperando',
    p_monto_precobrado,
    p_metodo_precobrado
  )
  returning id into v_turno_id;

  return v_turno_id;
end;
$$ language plpgsql security definer;

create or replace function llamar_turno(
  p_turno_id uuid,
  p_barbero_id uuid
)
returns void as $$
begin
  update turnos
  set estado = 'en_atencion',
      barbero_id = p_barbero_id,
      hora_atencion = now(),
      actualizado_en = now()
  where id = p_turno_id;
end;
$$ language plpgsql security definer;

create or replace function completar_turno(
  p_turno_id uuid,
  p_monto numeric default null,
  p_metodo text default null
)
returns uuid as $$
declare
  v_turno record;
  v_precio numeric;
  v_cita_id uuid;
begin
  select * into v_turno from turnos where id = p_turno_id;
  if v_turno.id is null then
    raise exception 'Turno no encontrado';
  end if;

  select precio into v_precio from servicios where id = v_turno.servicio_id;

  insert into citas (
    barberia_id,
    sucursal_id,
    barbero_id,
    cliente_id,
    servicio_id,
    fecha_hora,
    estado,
    precio_cobrado
  ) values (
    v_turno.barberia_id,
    v_turno.sucursal_id,
    v_turno.barbero_id,
    v_turno.cliente_id,
    v_turno.servicio_id,
    now(),
    'completada',
    coalesce(p_monto, v_precio)
  )
  returning id into v_cita_id;

  update turnos
  set estado = 'completado',
      cita_id = v_cita_id,
      hora_completado = now(),
      actualizado_en = now()
  where id = p_turno_id;

  return v_cita_id;
end;
$$ language plpgsql security definer;

create or replace function cancelar_turno(
  p_turno_id uuid
)
returns void as $$
begin
  update turnos
  set estado = 'cancelado',
      actualizado_en = now()
  where id = p_turno_id;
end;
$$ language plpgsql security definer;

create or replace function confirmar_llegada_cita(
  p_cita_id uuid
)
returns jsonb as $$
declare
  v_cita record;
  v_siguiente_numero int;
  v_turno_id uuid;
  v_resultado jsonb;
begin
  select * into v_cita from citas where id = p_cita_id;
  if v_cita.id is null then
    raise exception 'Cita no encontrada';
  end if;

  select coalesce(max(numero), 0) + 1 into v_siguiente_numero
  from turnos
  where sucursal_id = v_cita.sucursal_id
    and hora_llegada::date = current_date;

  insert into turnos (
    barberia_id,
    sucursal_id,
    numero,
    cliente_id,
    servicio_id,
    barbero_id,
    estado,
    cita_id,
    hora_llegada
  ) values (
    v_cita.barberia_id,
    v_cita.sucursal_id,
    v_siguiente_numero,
    v_cita.cliente_id,
    v_cita.servicio_id,
    v_cita.barbero_id,
    'esperando',
    p_cita_id,
    now()
  )
  returning id into v_turno_id;

  select row_to_json(t)::jsonb into v_resultado from turnos t where id = v_turno_id;
  return v_resultado;
end;
$$ language plpgsql security definer;
