--
-- Name: obtener_citas_atendidas_dia(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) RETURNS TABLE(cita_id uuid, hora timestamp with time zone, cliente_nombre text, servicio_nombre text, barbero_nombre text, monto numeric)
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
    c.id as cita_id,
    c.fecha_hora as hora,
    coalesce(p.nombre, cw.nombre, 'Cliente') as cliente_nombre,
    case
      when c.promocion_id is not null
        and jsonb_array_length(coalesce(promo.nombres_servicios, '[]'::jsonb)) > 1
      then array_to_string(
        array(select jsonb_array_elements_text(promo.nombres_servicios)),
        ' + '
      )
      else sv.nombre
    end as servicio_nombre,
    coalesce(bp.nombre, 'Barbero') as barbero_nombre,
    c.precio_cobrado as monto
  from public.citas c
  left join public.perfiles p on p.id = c.cliente_id
  left join public.clientes_walkin cw on cw.id = c.cliente_walkin_id
  left join public.servicios sv on sv.id = c.servicio_id
  left join public.promociones promo on promo.id = c.promocion_id
  left join public.barberos b on b.id = c.barbero_id
  left join public.perfiles bp on bp.id = b.perfil_id
  where c.barberia_id = v_barberia_id
    and c.estado = 'completada'
    and c.fecha_hora >= v_dia_inicio
    and c.fecha_hora < v_dia_fin
  order by c.fecha_hora asc;
end;
$$;


ALTER FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) OWNER TO postgres;
