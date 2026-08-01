--
-- Name: calcular_huecos_libres_hoy(uuid, integer, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid DEFAULT NULL::uuid) RETURNS TABLE(barbero_id uuid, hora_inicio timestamp with time zone, hora_fin timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_hoy date;
  v_dia_semana smallint;
  v_barbero record;
  v_horario record;
  v_inicio_jornada timestamptz;
  v_fin_jornada timestamptz;
  v_cursor timestamptz;
  v_turno record;
  v_dur_turno integer;
  v_libre_desde timestamptz;
  v_cita_activa record;
  v_ocupado record;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar huecos de esta sucursal.';
  end if;

  if p_duracion_min is null or p_duracion_min <= 0 then
    return;
  end if;

  -- "Hoy" y "ahora" en hora local de Bolivia (mismo criterio que 0013: la
  -- hora guardada en horarios_barbero es hora local, no UTC).
  v_hoy := (now() at time zone 'America/La_Paz')::date;
  v_dia_semana := extract(dow from v_hoy)::smallint;

  for v_barbero in
    select b.id
    from public.barberos b
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
  loop
    -- Paso 1: horario del barbero para hoy. Sin horario cargado ese dia =
    -- sin huecos para este barbero.
    select h.hora_inicio, h.hora_fin into v_horario
    from public.horarios_barbero h
    where h.barbero_id = v_barbero.id
      and h.dia_semana = v_dia_semana
    limit 1;

    if not found then
      continue;
    end if;

    v_inicio_jornada := ((v_hoy + v_horario.hora_inicio) at time zone 'America/La_Paz');
    v_fin_jornada := ((v_hoy + v_horario.hora_fin) at time zone 'America/La_Paz');

    -- Paso 2: cursor arranca en el mayor entre ahora y el inicio de jornada.
    v_cursor := greatest(now(), v_inicio_jornada);
    v_libre_desde := null;

    -- Paso 3: turno en_atencion ahora mismo (a lo sumo uno por barbero --
    -- llamar_turno, 0018, ya impide asignar un segundo turno en_atencion al
    -- mismo barbero mientras el primero sigue abierto).
    select t.hora_atencion, t.servicio_id into v_turno
    from public.turnos t
    where t.barbero_id = v_barbero.id
      and t.estado = 'en_atencion'
    limit 1;

    if found then
      if v_turno.hora_atencion is not null then
        select sv.duracion_min into v_dur_turno
        from public.servicios sv
        where sv.id = v_turno.servicio_id;

        if found then
          v_libre_desde := v_turno.hora_atencion + (v_dur_turno || ' minutes')::interval;
        end if;
      end if;

      -- Fail-safe: no se pudo estimar cuando termina (falta hora_atencion o
      -- no se encontro el servicio del turno) -> sin huecos hoy para este
      -- barbero, igual que el Dart.
      if v_libre_desde is null then
        continue;
      end if;
    else
      -- Paso 4: sin turno en curso, pero puede haber una cita
      -- pendiente/confirmada activa justo ahora (rol equivalente al turno
      -- en_atencion en el Dart).
      select c.fecha_hora, c.duracion_min into v_cita_activa
      from public.citas c
      where c.barbero_id = v_barbero.id
        and c.estado in ('pendiente', 'confirmada')
        and c.fecha_hora <= now()
        and now() < c.fecha_hora + (c.duracion_min || ' minutes')::interval
      limit 1;

      if found then
        v_libre_desde := v_cita_activa.fecha_hora + (v_cita_activa.duracion_min || ' minutes')::interval;
      end if;
    end if;

    if v_libre_desde is not null and v_libre_desde > v_cursor then
      v_cursor := v_libre_desde;
    end if;

    -- Paso 5: jornada ya cerrada (o por cerrar) para este barbero.
    if v_cursor >= v_fin_jornada then
      continue;
    end if;

    -- Paso 6/7: recorre las citas pendientes/confirmadas que se solapan con
    -- [cursor, fin_jornada), generando huecos entre ellas, y emite solo los
    -- que alcanzan para p_duracion_min.
    for v_ocupado in
      select c.fecha_hora as inicio,
             c.fecha_hora + (c.duracion_min || ' minutes')::interval as fin
      from public.citas c
      where c.barbero_id = v_barbero.id
        and c.estado in ('pendiente', 'confirmada')
        and c.fecha_hora + (c.duracion_min || ' minutes')::interval > v_cursor
        and c.fecha_hora < v_fin_jornada
      order by c.fecha_hora
    loop
      if v_ocupado.inicio > v_cursor
         and (v_ocupado.inicio - v_cursor) >= (p_duracion_min || ' minutes')::interval
      then
        barbero_id := v_barbero.id;
        hora_inicio := v_cursor;
        hora_fin := v_ocupado.inicio;
        return next;
      end if;
      if v_ocupado.fin > v_cursor then
        v_cursor := v_ocupado.fin;
      end if;
    end loop;

    if v_cursor < v_fin_jornada
       and (v_fin_jornada - v_cursor) >= (p_duracion_min || ' minutes')::interval
    then
      barbero_id := v_barbero.id;
      hora_inicio := v_cursor;
      hora_fin := v_fin_jornada;
      return next;
    end if;
  end loop;
end;
$$;


ALTER FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid) OWNER TO postgres;
