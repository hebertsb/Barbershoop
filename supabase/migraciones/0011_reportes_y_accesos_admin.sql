-- ============================================================================
-- BarberApp - Migración 0011: Reportes Financieros, Auditoría y Accesos Admin
-- ============================================================================

-- ----------------------------------------------------------------------------
-- accesos_admin_uso (Historial de accesos para el menú rápido)
-- ----------------------------------------------------------------------------

create table if not exists accesos_admin_uso (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references perfiles(id) on delete cascade,
  ruta text not null,
  creado_en timestamptz not null default now()
);

alter table accesos_admin_uso enable row level security;

create policy accesos_admin_uso_select on accesos_admin_uso
  for select using (perfil_id = auth.uid());

create policy accesos_admin_uso_insert on accesos_admin_uso
  for insert with check (perfil_id = auth.uid());

create or replace function obtener_accesos_rapidos_top(p_limite int default 4)
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select ruta, count(*) as uso_count
      from accesos_admin_uso
      where perfil_id = auth.uid()
        and creado_en >= (now() - interval '30 days')
      group by ruta
      order by uso_count desc
      limit p_limite
    ) r
  );
end;
$$ language plpgsql security definer;

-- ----------------------------------------------------------------------------
-- Reportes de Ingresos y Tendencia
-- ----------------------------------------------------------------------------

create or replace function obtener_resumen_ingresos(p_sucursal_id uuid default null)
returns json as $$
declare
  v_barberia_id uuid;
  v_hoy numeric;
  v_semana numeric;
  v_mes numeric;
begin
  v_barberia_id := obtener_barberia_id_actual();

  select coalesce(sum(precio_cobrado), 0) into v_hoy
  from citas
  where barberia_id = v_barberia_id
    and (p_sucursal_id is null or sucursal_id = p_sucursal_id)
    and estado = 'completada'
    and fecha_hora::date = current_date;

  select coalesce(sum(precio_cobrado), 0) into v_semana
  from citas
  where barberia_id = v_barberia_id
    and (p_sucursal_id is null or sucursal_id = p_sucursal_id)
    and estado = 'completada'
    and fecha_hora >= date_trunc('week', current_date);

  select coalesce(sum(precio_cobrado), 0) into v_mes
  from citas
  where barberia_id = v_barberia_id
    and (p_sucursal_id is null or sucursal_id = p_sucursal_id)
    and estado = 'completada'
    and fecha_hora >= date_trunc('month', current_date);

  return json_build_object(
    'ingresos_hoy', v_hoy,
    'ingresos_semana', v_semana,
    'ingresos_mes', v_mes
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_tendencia_ingresos(p_periodo text default 'semana')
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        fecha_hora::date::text as fecha,
        coalesce(sum(precio_cobrado), 0) as monto
      from citas
      where barberia_id = obtener_barberia_id_actual()
        and estado = 'completada'
        and fecha_hora >= (
          case p_periodo
            case 'semana' then (now() - interval '7 days')
            case 'mes' then (now() - interval '30 days')
            else (now() - interval '365 days')
          end
        )
      group by fecha_hora::date
      order by fecha asc
    ) r
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_resumen_ingresos_barbero()
returns json as $$
declare
  v_barbero_id uuid;
  v_hoy numeric;
  v_semana numeric;
  v_mes numeric;
begin
  select id into v_barbero_id from barberos where perfil_id = auth.uid() limit 1;

  select coalesce(sum(precio_cobrado), 0) into v_hoy
  from citas
  where barbero_id = v_barbero_id and estado = 'completada' and fecha_hora::date = current_date;

  select coalesce(sum(precio_cobrado), 0) into v_semana
  from citas
  where barbero_id = v_barbero_id and estado = 'completada' and fecha_hora >= date_trunc('week', current_date);

  select coalesce(sum(precio_cobrado), 0) into v_mes
  from citas
  where barbero_id = v_barbero_id and estado = 'completada' and fecha_hora >= date_trunc('month', current_date);

  return json_build_object(
    'ingresos_hoy', v_hoy,
    'ingresos_semana', v_semana,
    'ingresos_mes', v_mes
  );
end;
$$ language plpgsql security definer;

-- ----------------------------------------------------------------------------
-- Reportes de Ejecución y Auditoría
-- ----------------------------------------------------------------------------

create or replace function obtener_actividad_diaria(
  p_sucursal_id uuid default null,
  p_fecha date default current_date
)
returns json as $$
begin
  return (
    select json_build_object(
      'total_citas', count(*),
      'citas_completadas', count(*) filter (where estado = 'completada'),
      'citas_canceladas', count(*) filter (where estado = 'cancelada'),
      'citas_no_asistio', count(*) filter (where estado = 'no_asistio'),
      'total_recaudado', coalesce(sum(precio_cobrado) filter (where estado = 'completada'), 0)
    )
    from citas
    where barberia_id = obtener_barberia_id_actual()
      and (p_sucursal_id is null or sucursal_id = p_sucursal_id)
      and fecha_hora::date = p_fecha
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_auditoria_citas(
  p_sucursal_id uuid default null,
  p_limite int default 50
)
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        c.id as cita_id,
        c.fecha_hora,
        c.estado,
        c.precio_cobrado,
        p_cli.nombre as nombre_cliente,
        p_bar.nombre as nombre_barbero,
        s.nombre as nombre_servicio
      from citas c
      left join perfiles p_cli on p_cli.id = c.cliente_id
      left join barberos b on b.id = c.barbero_id
      left join perfiles p_bar on p_bar.id = b.perfil_id
      join servicios s on s.id = c.servicio_id
      where c.barberia_id = obtener_barberia_id_actual()
        and (p_sucursal_id is null or c.sucursal_id = p_sucursal_id)
      order by c.actualizado_en desc
      limit p_limite
    ) r
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_reporte_ingresos_por_metodo(
  p_sucursal_id uuid default null,
  p_fecha_inicio timestamptz default (now() - interval '30 days'),
  p_fecha_fin timestamptz default now()
)
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        coalesce(pg.metodo, 'efectivo') as metodo,
        sum(c.precio_cobrado) as total
      from citas c
      left join pagos pg on pg.cita_id = c.id
      where c.barberia_id = obtener_barberia_id_actual()
        and (p_sucursal_id is null or c.sucursal_id = p_sucursal_id)
        and c.estado = 'completada'
        and c.fecha_hora between p_fecha_inicio and p_fecha_fin
      group by coalesce(pg.metodo, 'efectivo')
    ) r
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_reporte_top_servicios(
  p_sucursal_id uuid default null,
  p_fecha_inicio timestamptz default (now() - interval '30 days'),
  p_fecha_fin timestamptz default now()
)
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        s.nombre as servicio,
        count(c.id) as cantidad,
        sum(c.precio_cobrado) as total
      from citas c
      join servicios s on s.id = c.servicio_id
      where c.barberia_id = obtener_barberia_id_actual()
        and (p_sucursal_id is null or c.sucursal_id = p_sucursal_id)
        and c.estado = 'completada'
        and c.fecha_hora between p_fecha_inicio and p_fecha_fin
      group by s.nombre
      order by cantidad desc
    ) r
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_reporte_top_barberos(
  p_sucursal_id uuid default null,
  p_fecha_inicio timestamptz default (now() - interval '30 days'),
  p_fecha_fin timestamptz default now()
)
returns json as $$
begin
  return (
    select coalesce(json_agg(row_to_json(r)), '[]'::json)
    from (
      select
        p.nombre as barbero,
        count(c.id) as cantidad_citas,
        sum(c.precio_cobrado) as total_recaudado
      from citas c
      join barberos b on b.id = c.barbero_id
      join perfiles p on p.id = b.perfil_id
      where c.barberia_id = obtener_barberia_id_actual()
        and (p_sucursal_id is null or c.sucursal_id = p_sucursal_id)
        and c.estado = 'completada'
        and c.fecha_hora between p_fecha_inicio and p_fecha_fin
      group by p.nombre
      order by total_recaudado desc
    ) r
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_reporte_ausentismo(
  p_sucursal_id uuid default null,
  p_fecha_inicio timestamptz default (now() - interval '30 days'),
  p_fecha_fin timestamptz default now()
)
returns json as $$
begin
  return (
    select json_build_object(
      'total_citas', count(*),
      'asistidas', count(*) filter (where estado = 'completada'),
      'no_asistidas', count(*) filter (where estado = 'no_asistio'),
      'tasa_ausentismo', case when count(*) > 0 then (count(*) filter (where estado = 'no_asistio')::numeric / count(*)::numeric) * 100.0 else 0 end
    )
    from citas
    where barberia_id = obtener_barberia_id_actual()
      and (p_sucursal_id is null or sucursal_id = p_sucursal_id)
      and fecha_hora between p_fecha_inicio and p_fecha_fin
  );
end;
$$ language plpgsql security definer;

create or replace function obtener_reporte_retencion_clientes(
  p_sucursal_id uuid default null
)
returns json as $$
begin
  return (
    select json_build_object(
      'total_clientes_unicos', count(distinct cliente_id),
      'clientes_reincidentes', count(distinct cliente_id) filter (where cantidad_citas > 1)
    )
    from (
      select cliente_id, count(*) as cantidad_citas
      from citas
      where barberia_id = obtener_barberia_id_actual()
        and (p_sucursal_id is null or sucursal_id = p_sucursal_id)
        and estado = 'completada'
      group by cliente_id
    ) t
  );
end;
$$ language plpgsql security definer;
