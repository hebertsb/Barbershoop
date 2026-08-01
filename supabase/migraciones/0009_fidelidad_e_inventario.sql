-- ============================================================================
-- BarberApp - Migración 0009: Fidelidad de Clientes e Inventario
-- ============================================================================

-- ----------------------------------------------------------------------------
-- programas_fidelidad
-- ----------------------------------------------------------------------------

create table if not exists programas_fidelidad (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  titulo text not null,
  descripcion text,
  citas_requeridas int not null default 5,
  servicio_premio_id uuid references servicios(id) on delete set null,
  descuento_porcentaje numeric default 100,
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

alter table programas_fidelidad enable row level security;

create policy programas_fidelidad_select on programas_fidelidad
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy programas_fidelidad_escritura_admin on programas_fidelidad
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- progreso_fidelidad
-- ----------------------------------------------------------------------------

create table if not exists progreso_fidelidad (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references perfiles(id) on delete cascade,
  programa_id uuid not null references programas_fidelidad(id) on delete cascade,
  citas_acumuladas int not null default 0,
  premios_reclamados int not null default 0,
  actualizado_en timestamptz not null default now(),
  unique (cliente_id, programa_id)
);

alter table progreso_fidelidad enable row level security;

create policy progreso_fidelidad_select on progreso_fidelidad
  for select using (
    es_superadmin() or cliente_id = auth.uid() or es_admin_o_superior()
  );

create policy progreso_fidelidad_escritura on progreso_fidelidad
  for all using (
    es_superadmin() or cliente_id = auth.uid() or es_admin_o_superior()
  );

-- RPC: obtener_progreso_fidelidad_cliente
create or replace function obtener_progreso_fidelidad_cliente()
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        pf.id as programa_id,
        pf.titulo,
        pf.descripcion,
        pf.citas_requeridas,
        coalesce(pr.citas_acumuladas, 0) as citas_acumuladas,
        coalesce(pr.premios_reclamados, 0) as premios_reclamados
      from programas_fidelidad pf
      left join progreso_fidelidad pr
        on pr.programa_id = pf.id and pr.cliente_id = auth.uid()
      where pf.activo = true
        and pf.barberia_id = obtener_barberia_id_actual()
    ) r
  );
end;
$$ language plpgsql security definer;

-- RPC: reclamar_premio_fidelidad
create or replace function reclamar_premio_fidelidad(p_programa_id uuid)
returns void as $$
declare
  v_req int;
  v_acum int;
begin
  select citas_requeridas into v_req from programas_fidelidad where id = p_programa_id;
  select citas_acumuladas into v_acum from progreso_fidelidad where programa_id = p_programa_id and cliente_id = auth.uid();

  if v_acum is null or v_acum < v_req then
    raise exception 'No acumulaste suficientes citas para reclamar este premio';
  end if;

  update progreso_fidelidad
  set citas_acumuladas = citas_acumuladas - v_req,
      premios_reclamados = premios_reclamados + 1,
      actualizado_en = now()
  where programa_id = p_programa_id and cliente_id = auth.uid();
end;
$$ language plpgsql security definer;

-- ----------------------------------------------------------------------------
-- Inventario RPCs
-- ----------------------------------------------------------------------------

-- RPC: asignar_insumo_barbero
create or replace function asignar_insumo_barbero(
  p_barbero_id uuid,
  p_insumo_id uuid,
  p_cantidad int
)
returns void as $$
declare
  v_stock int;
  v_barberia_id uuid;
begin
  select stock, barberia_id into v_stock, v_barberia_id from insumos where id = p_insumo_id;
  if v_stock < p_cantidad then
    raise exception 'Stock insuficiente en almacén';
  end if;

  update insumos set stock = stock - p_cantidad where id = p_insumo_id;

  insert into insumos_barbero (barberia_id, barbero_id, insumo_id, cantidad_asignada)
  values (v_barberia_id, p_barbero_id, p_insumo_id, p_cantidad)
  on conflict (barbero_id, insumo_id)
  do update set cantidad_asignada = insumos_barbero.cantidad_asignada + excluded.cantidad_asignada;
end;
$$ language plpgsql security definer;

-- RPC: reportar_insumo
create or replace function reportar_insumo(
  p_insumo_id uuid,
  p_tipo text,
  p_cantidad int,
  p_descripcion text
)
returns uuid as $$
declare
  v_barbero_id uuid;
  v_barberia_id uuid;
  v_id uuid;
begin
  select id, barberia_id into v_barbero_id, v_barberia_id
  from barberos
  where perfil_id = auth.uid()
  limit 1;

  if v_barbero_id is null then
    raise exception 'Barbero no encontrado para el usuario actual';
  end if;

  insert into reportes_insumo (
    barberia_id, barbero_id, insumo_id, tipo, descripcion, estado
  ) values (
    v_barberia_id, v_barbero_id, p_insumo_id, p_tipo::tipo_reporte_insumo, p_descripcion, 'pendiente'
  )
  returning id into v_id;

  return v_id;
end;
$$ language plpgsql security definer;

-- RPC: resolver_reporte_insumo
create or replace function resolver_reporte_insumo(
  p_reporte_id uuid,
  p_estado text
)
returns void as $$
begin
  update reportes_insumo
  set estado = p_estado::estado_reporte_insumo,
      actualizado_en = now()
  where id = p_reporte_id;
end;
$$ language plpgsql security definer;
