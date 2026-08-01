--
-- Name: obtener_reporte_clientes_frecuentes(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(cliente_id uuid, cliente_nombre text, cantidad_citas bigint, monto_total numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar los reportes de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    c.cliente_id,
    coalesce(p.nombre, 'Cliente') as cliente_nombre,
    count(c.id) as cantidad_citas,
    coalesce(sum(c.precio_cobrado), 0) as monto_total
  from public.citas c
  left join public.perfiles p on p.id = c.cliente_id
  where c.barberia_id = v_barberia_id
    and c.cliente_id is not null
    and c.estado = 'completada'
    and c.fecha_hora >= p_fecha_inicio
    and c.fecha_hora <= p_fecha_fin
  group by c.cliente_id, p.nombre
  order by cantidad_citas desc, monto_total desc
  limit 20;
end;
$$;


ALTER FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;
