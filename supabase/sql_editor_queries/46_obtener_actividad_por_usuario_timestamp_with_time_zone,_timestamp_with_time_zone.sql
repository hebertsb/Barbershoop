--
-- Name: obtener_actividad_por_usuario(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(usuario_id uuid, usuario_nombre text, rol text, citas_completadas bigint, monto_total_cobrado numeric, citas_canceladas bigint)
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
  with completadas as (
    select
      c.completado_por as usuario_id,
      count(*) as citas_completadas,
      coalesce(sum(c.precio_cobrado), 0) as monto_total_cobrado
    from public.citas c
    where c.barberia_id = v_barberia_id
      and c.completado_por is not null
      and c.estado = 'completada'
      and c.fecha_hora >= p_fecha_inicio
      and c.fecha_hora <= p_fecha_fin
    group by c.completado_por
  ),
  canceladas as (
    select
      c.cancelado_por as usuario_id,
      count(*) as citas_canceladas
    from public.citas c
    where c.barberia_id = v_barberia_id
      and c.cancelado_por is not null
      and c.estado in ('cancelada', 'no_asistio')
      and c.fecha_hora >= p_fecha_inicio
      and c.fecha_hora <= p_fecha_fin
    group by c.cancelado_por
  )
  select
    coalesce(comp.usuario_id, canc.usuario_id) as usuario_id,
    coalesce(p.nombre, 'Usuario') as usuario_nombre,
    p.rol::text as rol,
    coalesce(comp.citas_completadas, 0) as citas_completadas,
    coalesce(comp.monto_total_cobrado, 0) as monto_total_cobrado,
    coalesce(canc.citas_canceladas, 0) as citas_canceladas
  from completadas comp
  full outer join canceladas canc on canc.usuario_id = comp.usuario_id
  left join public.perfiles p on p.id = coalesce(comp.usuario_id, canc.usuario_id)
  order by citas_completadas desc;
end;
$$;


ALTER FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;
