--
-- Name: obtener_clientes_nuevos_dia(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) RETURNS TABLE(cliente_id uuid, nombre text, telefono text, hora_registro timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_dia_inicio timestamptz;
  v_dia_fin timestamptz;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar la actividad diaria.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  v_dia_inicio := p_fecha::timestamp at time zone 'America/La_Paz';
  v_dia_fin := v_dia_inicio + interval '1 day';

  return query
  select
    p.id as cliente_id,
    p.nombre,
    p.telefono,
    p.creado_en as hora_registro
  from public.perfiles p
  where p.barberia_id = v_barberia_id
    and p.rol = 'cliente'
    and p.creado_en >= v_dia_inicio
    and p.creado_en < v_dia_fin
  order by p.creado_en asc;
end;
$$;


ALTER FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) OWNER TO postgres;
