--
-- Name: obtener_horarios_disponibles(uuid, uuid, date, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid DEFAULT NULL::uuid) RETURNS TABLE(barbero_id uuid, hora_inicio timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_es_hoy boolean;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar horarios de esta sucursal.';
  end if;

  -- sv.barberia_id = v_barberia_id: sin esto, un servicio_id de OTRA
  -- barbería pasaría el chequeo (duracion_min existe igual) y filtraria
  -- horarios con una duracion ajena al tenant.
  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  v_es_hoy := p_fecha = (now() at time zone 'America/La_Paz')::date;

  if v_es_hoy then
    return query
    select b.id as barbero_id, slot.hora_inicio
    from public.barberos b
    join public.horarios_barbero h
      on h.barbero_id = b.id
     and h.dia_semana = extract(dow from p_fecha)::smallint
    cross join lateral (
      -- generate_series no funciona directo sobre "time": se genera un
      -- contador entero n (uno por slot) y se le suma su offset en minutos
      -- a hora_inicio. Cuando el rango no da para ningun slot completo
      -- (numero <= 0), generate_series(0, -1) devuelve cero filas.
      select
        ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
          + (n * v_duracion_min || ' minutes')::interval as hora_inicio
      from generate_series(
        0,
        (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
      ) as n
    ) as slot
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
      -- Excluye slots que se solapan con una cita ya tomada de ese barbero
      -- (comparacion de intervalos semiabiertos [inicio, fin)). Incluye
      -- 'completada' ademas de 'pendiente'/'confirmada' para quedar de
      -- acuerdo con idx_citas_barbero_fecha_hora_activa (0024): una cita ya
      -- atendida en ese horario+barbero sigue siendo un dato real, no un
      -- hueco libre para re-reservar.
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    union
    -- Huecos reales de HOY (ver calcular_huecos_libres_hoy mas arriba). El
    -- UNION (no union all) descarta el caso borde en que un hueco arranque
    -- justo en un slot de la grilla que ya estaba libre. El if externo ya
    -- garantiza que solo se llega aca cuando p_fecha es hoy, por eso no
    -- hace falta repetir el filtro de fecha sobre calcular_huecos_libres_hoy.
    select huecos.barbero_id, huecos.hora_inicio
    from public.calcular_huecos_libres_hoy(p_sucursal_id, v_duracion_min, p_barbero_id) as huecos
    order by hora_inicio, barbero_id;
  else
    -- Fecha distinta de hoy: solo la grilla fija, identica a la de arriba,
    -- sin invocar calcular_huecos_libres_hoy en absoluto.
    return query
    select b.id as barbero_id, slot.hora_inicio
    from public.barberos b
    join public.horarios_barbero h
      on h.barbero_id = b.id
     and h.dia_semana = extract(dow from p_fecha)::smallint
    cross join lateral (
      select
        ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
          + (n * v_duracion_min || ' minutes')::interval as hora_inicio
      from generate_series(
        0,
        (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
      ) as n
    ) as slot
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    order by hora_inicio, barbero_id;
  end if;
end;
$$;


ALTER FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) OWNER TO postgres;
