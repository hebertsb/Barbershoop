--
-- Name: obtener_ingresos_por_metodo_pago(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(metodo text, monto_total numeric, cantidad_pagos bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar este reporte.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    pg.metodo::text as metodo,
    coalesce(sum(pg.monto), 0) as monto_total,
    count(*) as cantidad_pagos
  from public.pagos pg
  where pg.barberia_id = v_barberia_id
    and pg.estado = 'confirmado'
    and pg.fecha >= p_fecha_inicio
    and pg.fecha <= p_fecha_fin
  group by pg.metodo
  order by monto_total desc;
end;
$$;


ALTER FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;
