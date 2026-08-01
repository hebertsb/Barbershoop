-- ============================================================================
-- BarberApp - Migración 0010: Ranking de Barberos, Promociones y Reseñas
-- ============================================================================

-- ----------------------------------------------------------------------------
-- resenas (Calificaciones y opiniones de clientes a citas/barberos)
-- ----------------------------------------------------------------------------

create table if not exists resenas (
  id uuid primary key default gen_random_uuid(),
  barberia_id uuid not null references barberias(id) on delete cascade,
  cita_id uuid references citas(id) on delete set null,
  cliente_id uuid not null references perfiles(id) on delete cascade,
  barbero_id uuid references barberos(id) on delete set null,
  puntuacion int not null check (puntuacion >= 1 and puntuacion <= 5),
  comentario text,
  creado_en timestamptz not null default now()
);

alter table resenas enable row level security;

create policy resenas_select on resenas
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy resenas_insert on resenas
  for insert with check (
    cliente_id = auth.uid() or es_admin_o_superior()
  );

-- ----------------------------------------------------------------------------
-- usos_promocion
-- ----------------------------------------------------------------------------

create table if not exists usos_promocion (
  id uuid primary key default gen_random_uuid(),
  promocion_id uuid not null references promociones(id) on delete cascade,
  cliente_id uuid not null references perfiles(id) on delete cascade,
  cita_id uuid references citas(id) on delete set null,
  creado_en timestamptz not null default now()
);

alter table usos_promocion enable row level security;

create policy usos_promocion_select on usos_promocion
  for select using (
    es_superadmin() or cliente_id = auth.uid() or es_admin_o_superior()
  );

create policy usos_promocion_insert on usos_promocion
  for insert with check (
    cliente_id = auth.uid() or es_admin_o_superior()
  );

-- RPC: validar_promocion
create or replace function validar_promocion(
  p_promocion_id uuid,
  p_servicio_id uuid default null,
  p_monto numeric default null
)
returns jsonb as $$
declare
  v_promo record;
  v_descuento numeric;
begin
  select * into v_promo from promociones where id = p_promocion_id and activo = true;
  if v_promo.id is null then
    return jsonb_build_object('valido', false, 'mensaje', 'Promoción no encontrada o inactiva');
  end if;

  if v_promo.fecha_inicio is not null and v_promo.fecha_inicio > now() then
    return jsonb_build_object('valido', false, 'mensaje', 'La promoción aún no ha comenzado');
  end if;

  if v_promo.fecha_fin is not null and v_promo.fecha_fin < now() then
    return jsonb_build_object('valido', false, 'mensaje', 'La promoción ha expirado');
  end if;

  v_descuento := coalesce(p_monto * (v_promo.descuento / 100.0), 0);

  return jsonb_build_object(
    'valido', true,
    'promocion_id', v_promo.id,
    'titulo', v_promo.titulo,
    'descuento_monto', v_descuento
  );
end;
$$ language plpgsql security definer;

-- ----------------------------------------------------------------------------
-- Ranking de Barberos
-- ----------------------------------------------------------------------------

create or replace function obtener_ranking_barberos(p_periodo_meses int default 1)
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        b.id as barbero_id,
        p.nombre,
        p.url_foto,
        count(c.id) as total_citas,
        coalesce(sum(c.precio_cobrado), 0) as total_ingresos,
        coalesce(avg(r.puntuacion), 5.0) as promedio_calificacion,
        rank() over (order by count(c.id) desc, sum(c.precio_cobrado) desc) as puesto
      from barberos b
      join perfiles p on p.id = b.perfil_id
      left join citas c on c.barbero_id = b.id and c.estado = 'completada' and c.fecha_hora >= (now() - (p_periodo_meses || ' month')::interval)
      left join resenas r on r.cita_id = c.id
      where b.barberia_id = obtener_barberia_id_actual()
        and b.activo = true
      group by b.id, p.nombre, p.url_foto
      order by puesto asc
    ) r
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_mi_ranking_barbero(p_periodo_meses int default 1)
returns json as $$
declare
  v_barbero_id uuid;
begin
  select id into v_barbero_id from barberos where perfil_id = auth.uid() limit 1;

  return (
    select row_to_json(r)::json
    from (
      select * from json_to_recordset(obtener_ranking_barberos(p_periodo_meses))
      as x(barbero_id uuid, nombre text, url_foto text, total_citas bigint, total_ingresos numeric, promedio_calificacion numeric, puesto bigint)
      where x.barbero_id = v_barbero_id
    ) r
  );
end;
$$ language plpgsql security definer;

-- ----------------------------------------------------------------------------
-- Reseñas RPCs
-- ----------------------------------------------------------------------------

create or replace function crear_resena(
  p_cita_id uuid,
  p_puntuacion int,
  p_comentario text default null
)
returns uuid as $$
declare
  v_cita record;
  v_resena_id uuid;
begin
  select * into v_cita from citas where id = p_cita_id;
  if v_cita.id is null then
    raise exception 'Cita no encontrada';
  end if;

  insert into resenas (
    barberia_id,
    cita_id,
    cliente_id,
    barbero_id,
    puntuacion,
    comentario,
    creado_en
  ) values (
    v_cita.barberia_id,
    p_cita_id,
    v_cita.cliente_id,
    v_cita.barbero_id,
    p_puntuacion,
    p_comentario,
    now()
  )
  returning id into v_resena_id;

  return v_resena_id;
end;
$$ language plpgsql security definer;

create or replace function obtener_mis_resenas()
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        r.id,
        r.puntuacion,
        r.comentario,
        r.creado_en,
        s.nombre as nombre_servicio,
        pb.nombre as nombre_barbero
      from resenas r
      join citas c on c.id = r.cita_id
      join servicios s on s.id = c.servicio_id
      left join barberos b on b.id = r.barbero_id
      left join perfiles pb on pb.id = b.perfil_id
      where r.cliente_id = auth.uid()
      order by r.creado_en desc
    ) r
  );
end;
$$ language plpgsql security definer;
