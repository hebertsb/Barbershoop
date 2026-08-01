--
-- Name: obtener_resumen_ingresos_barbero(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_resumen_ingresos_barbero() RETURNS TABLE(ingresos_hoy numeric, ingresos_semana numeric, ingresos_mes numeric, citas_hoy integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_perfil_id uuid := auth.uid();
  v_hoy_inicio timestamptz;
  v_hoy_fin timestamptz;
  v_semana_inicio timestamptz;
  v_semana_fin timestamptz;
  v_mes_inicio timestamptz;
  v_mes_fin timestamptz;
  v_scan_desde timestamptz;
begin
  if v_perfil_id is null then
    raise exception 'Sesión no iniciada.';
  end if;

  v_hoy_inicio := date_trunc('day', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_hoy_fin := v_hoy_inicio + interval '1 day';

  v_semana_inicio := date_trunc('week', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_semana_fin := v_semana_inicio + interval '1 week';

  v_mes_inicio := date_trunc('month', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_mes_fin := v_mes_inicio + interval '1 month';

  v_scan_desde := least(v_semana_inicio, v_mes_inicio);

  return query
  select
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
    ), 0) as ingresos_hoy,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_semana_inicio and c.fecha_hora < v_semana_fin
    ), 0) as ingresos_semana,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_mes_inicio and c.fecha_hora < v_mes_fin
    ), 0) as ingresos_mes,
    count(*) filter (
      where c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
        and c.estado not in ('cancelada', 'no_asistio')
    )::integer as citas_hoy
  from public.citas c
  where c.barbero_id in (
    select b.id from public.barberos b where b.perfil_id = v_perfil_id
  )
  and c.fecha_hora >= v_scan_desde;
end;
$$;


ALTER FUNCTION public.obtener_resumen_ingresos_barbero() OWNER TO postgres;
