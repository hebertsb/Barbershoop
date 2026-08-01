--
-- Name: obtener_grilla_horarios(uuid, uuid, date, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid DEFAULT NULL::uuid) RETURNS TABLE(hora_inicio timestamp with time zone, libre boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_promo record;
  v_duracion_combo integer;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar horarios de esta sucursal.';
  end if;

  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  -- Mismo override de duracion para combos que obtener_horarios_disponibles
  -- (ver comentario de cabecera de esta migracion).
  if p_promocion_id is not null then
    select * into v_promo
    from public.promociones
    where id = p_promocion_id
      and barberia_id = v_barberia_id;

    if v_promo is not null
       and v_promo.servicios_ids is not null
       and jsonb_array_length(v_promo.servicios_ids) > 1
    then
      select coalesce(sum(sv.duracion_min), 0) into v_duracion_combo
      from public.servicios sv
      where sv.id in (
        select jsonb_array_elements_text(v_promo.servicios_ids)::uuid
      )
      and sv.barberia_id = v_barberia_id;

      if v_duracion_combo > 0 then
        v_duracion_min := v_duracion_combo;
      end if;
    end if;
  end if;

  if not exists (
    select 1 from public.barberos b
    where b.id = p_barbero_id
      and b.sucursal_id = p_sucursal_id
      and b.activo = true
  ) then
    raise exception 'Barbero no encontrado.';
  end if;

  return query
  select
    slot.hora_inicio,
    not exists (
      select 1
      from public.citas c
      where c.barbero_id = p_barbero_id
        and c.estado in ('pendiente', 'confirmada', 'completada')
        and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
        and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
    ) as libre
  from public.horarios_barbero h
  cross join lateral (
    select
      ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
        + (n * v_duracion_min || ' minutes')::interval as hora_inicio
    from generate_series(
      0,
      (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
    ) as n
  ) as slot
  where h.barbero_id = p_barbero_id
    and h.dia_semana = extract(dow from p_fecha)::smallint
    and slot.hora_inicio >= now()
  order by slot.hora_inicio;
end;
$$;


ALTER FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) OWNER TO postgres;
