--
-- Name: obtener_resumen_ingresos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_resumen_ingresos() RETURNS TABLE(ingresos_hoy numeric, ingresos_mes numeric, ingresos_anio numeric, citas_hoy integer, ingresos_ayer numeric, citas_ayer integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_hoy_inicio timestamptz;
  v_hoy_fin timestamptz;
  v_ayer_inicio timestamptz;
  v_mes_inicio timestamptz;
  v_mes_fin timestamptz;
  v_anio_inicio timestamptz;
  v_anio_fin timestamptz;
  v_scan_inicio timestamptz;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar el resumen de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  v_hoy_inicio := date_trunc('day', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_hoy_fin := v_hoy_inicio + interval '1 day';
  v_ayer_inicio := v_hoy_inicio - interval '1 day';

  v_mes_inicio := date_trunc('month', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_mes_fin := v_mes_inicio + interval '1 month';

  v_anio_inicio := date_trunc('year', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_anio_fin := v_anio_inicio + interval '1 year';

  -- "Ayer" puede caer en el año calendario ANTERIOR (si hoy es 1 de enero),
  -- fuera del rango [v_anio_inicio, v_anio_fin) que hasta ahora acotaba todo
  -- el scan (ya cubría "hoy" y "este mes" sin este caso límite) -- mismo
  -- caso límite que ya resuelve obtener_resumen_ingresos_barbero (0044) con
  -- least(semana_inicio, mes_inicio). Se amplía solo el límite INFERIOR del
  -- scan; ingresos_anio conserva su propio filtro exacto [v_anio_inicio,
  -- v_anio_fin) más abajo para no arrastrar de más si el scan crece.
  v_scan_inicio := least(v_anio_inicio, v_ayer_inicio);

  -- Un solo scan lógico sobre citas (acotado a v_scan_inicio..v_anio_fin)
  -- con "filter" por métrica en vez de selects sueltos, mismo patrón que la
  -- versión original de esta función (0030): cada rango es un acumulador
  -- independiente, ninguno se calcula a partir de otro.
  return query
  select
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
    ), 0) as ingresos_hoy,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_mes_inicio and c.fecha_hora < v_mes_fin
    ), 0) as ingresos_mes,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_anio_inicio and c.fecha_hora < v_anio_fin
    ), 0) as ingresos_anio,
    count(*) filter (
      where c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
        and c.estado not in ('cancelada', 'no_asistio')
    )::integer as citas_hoy,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_ayer_inicio and c.fecha_hora < v_hoy_inicio
    ), 0) as ingresos_ayer,
    count(*) filter (
      where c.fecha_hora >= v_ayer_inicio and c.fecha_hora < v_hoy_inicio
        and c.estado not in ('cancelada', 'no_asistio')
    )::integer as citas_ayer
  from public.citas c
  where c.barberia_id = v_barberia_id
    and c.fecha_hora >= v_scan_inicio
    and c.fecha_hora < v_anio_fin;
end;
$$;


ALTER FUNCTION public.obtener_resumen_ingresos() OWNER TO postgres;
