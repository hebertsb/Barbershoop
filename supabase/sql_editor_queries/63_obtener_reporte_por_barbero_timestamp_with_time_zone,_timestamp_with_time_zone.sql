--
-- Name: obtener_reporte_por_barbero(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(barbero_id uuid, barbero_nombre text, cantidad_citas integer, ingresos_totales numeric)
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
    b.id as barbero_id,
    coalesce(p.nombre, 'Barbero') as barbero_nombre,
    count(c.id)::integer as cantidad_citas,
    coalesce(sum(c.precio_cobrado), 0) as ingresos_totales
  from public.barberos b
  left join public.perfiles p on p.id = b.perfil_id
  left join public.citas c
    on c.barbero_id = b.id
   and c.estado = 'completada'
   and c.fecha_hora >= p_fecha_inicio
   and c.fecha_hora <= p_fecha_fin
  where b.barberia_id = v_barberia_id
  group by b.id, p.nombre
  order by ingresos_totales desc, cantidad_citas desc;
end;
$$;


ALTER FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;
