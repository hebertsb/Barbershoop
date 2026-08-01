--
-- Name: obtener_citas_sin_pago_completo(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(cita_id uuid, fecha_hora timestamp with time zone, cliente_nombre text, barbero_nombre text, precio_cobrado numeric, monto_pagado numeric, diferencia numeric)
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
    c.id as cita_id,
    c.fecha_hora,
    coalesce(p_cliente.nombre, cw.nombre, 'Cliente') as cliente_nombre,
    coalesce(p_barbero.nombre, 'Barbero') as barbero_nombre,
    coalesce(c.precio_cobrado, 0) as precio_cobrado,
    coalesce(pc.monto_pagado, 0) as monto_pagado,
    (coalesce(c.precio_cobrado, 0) - coalesce(pc.monto_pagado, 0)) as diferencia
  from public.citas c
  left join public.perfiles p_cliente on p_cliente.id = c.cliente_id
  left join public.clientes_walkin cw on cw.id = c.cliente_walkin_id
  left join public.barberos b on b.id = c.barbero_id
  left join public.perfiles p_barbero on p_barbero.id = b.perfil_id
  left join lateral (
    select coalesce(sum(pg.monto), 0) as monto_pagado
    from public.pagos pg
    where pg.cita_id = c.id and pg.estado = 'confirmado'
  ) pc on true
  where c.barberia_id = v_barberia_id
    and c.estado = 'completada'
    and c.fecha_hora >= p_fecha_inicio
    and c.fecha_hora <= p_fecha_fin
    and (coalesce(c.precio_cobrado, 0) - coalesce(pc.monto_pagado, 0)) > 0
  order by diferencia desc;
end;
$$;


ALTER FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;
