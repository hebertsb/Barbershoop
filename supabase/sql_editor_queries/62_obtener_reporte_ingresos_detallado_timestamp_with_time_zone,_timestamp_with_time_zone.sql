--
-- Name: obtener_reporte_ingresos_detallado(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(total_ingresos numeric, total_descuentos numeric, citas_completadas integer, citas_canceladas integer, ticket_promedio numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_ingresos numeric := 0;
  v_descuentos numeric := 0;
  v_completadas integer := 0;
  v_canceladas integer := 0;
  v_ticket numeric := 0;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar los reportes de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  select
    coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0),
    coalesce(sum(c.descuento_aplicado) filter (where c.estado = 'completada'), 0),
    count(*) filter (where c.estado = 'completada')::integer,
    count(*) filter (where c.estado in ('cancelada', 'no_asistio'))::integer
  into v_ingresos, v_descuentos, v_completadas, v_canceladas
  from public.citas c
  where c.barberia_id = v_barberia_id
    and c.fecha_hora >= p_fecha_inicio
    and c.fecha_hora <= p_fecha_fin;

  if v_completadas > 0 then
    v_ticket := round(v_ingresos / v_completadas, 2);
  else
    v_ticket := 0;
  end if;

  return query
  select v_ingresos, v_descuentos, v_completadas, v_canceladas, v_ticket;
end;
$$;


ALTER FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;
