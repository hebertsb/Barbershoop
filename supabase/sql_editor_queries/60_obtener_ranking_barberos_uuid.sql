--
-- Name: obtener_ranking_barberos(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) RETURNS TABLE(barbero_id uuid, nombre text, puesto integer, puntaje numeric, citas_completadas integer, puesto_citas integer, ingresos_generados numeric, puesto_ingresos integer, clientes_distintos integer, puesto_clientes integer, tasa_no_show numeric, puesto_puntualidad integer, calificacion_promedio numeric, puesto_calificacion integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_programa programas_ranking_barberos;
  v_desde timestamptz;
  v_hasta timestamptz;
begin
  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa is null then
    raise exception 'Programa no encontrado.';
  end if;
  if v_programa.barberia_id != obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para ver este programa.';
  end if;

  v_desde := (v_programa.fecha_inicio::timestamp at time zone 'America/La_Paz');
  v_hasta := ((v_programa.fecha_fin + 1)::timestamp at time zone 'America/La_Paz');

  return query
  with base as (
    select
      b.id as barbero_id,
      p.nombre as nombre,
      coalesce(count(c.id) filter (where c.estado = 'completada'), 0)::integer as citas_completadas,
      coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as ingresos_generados,
      coalesce(count(distinct c.cliente_id) filter (where c.estado = 'completada'), 0)::integer as clientes_distintos,
      case
        when count(c.id) filter (where c.estado in ('completada', 'no_asistio')) = 0 then 0
        else count(c.id) filter (where c.estado = 'no_asistio')::numeric
             / count(c.id) filter (where c.estado in ('completada', 'no_asistio'))::numeric
      end as tasa_no_show,
      coalesce(avg(res.calificacion), 0) as calificacion_promedio
    from public.barberos b
    join public.perfiles p on p.id = b.perfil_id
    left join public.citas c
      on c.barbero_id = b.id
      and c.fecha_hora >= v_desde
      and c.fecha_hora < v_hasta
    left join public.resenas res
      on res.cita_id = c.id
    where b.sucursal_id = v_programa.sucursal_id
      and (
        b.activo = true
        or exists (
          select 1 from public.citas c2
          where c2.barbero_id = b.id
            and c2.fecha_hora >= v_desde
            and c2.fecha_hora < v_hasta
        )
      )
    group by b.id, p.nombre
  ),
  maximos as (
    select
      greatest(max(citas_completadas), 1) as max_citas,
      greatest(max(ingresos_generados), 1) as max_ingresos,
      greatest(max(clientes_distintos), 1) as max_clientes
    from base
  ),
  puntuado as (
    select
      base.*,
      (base.citas_completadas::numeric / maximos.max_citas * 100) as score_citas,
      (base.ingresos_generados / maximos.max_ingresos * 100) as score_ingresos,
      (base.clientes_distintos::numeric / maximos.max_clientes * 100) as score_clientes,
      ((1 - base.tasa_no_show) * 100) as score_puntualidad,
      (base.calificacion_promedio / 5 * 100) as score_calificacion
    from base, maximos
  ),
  final as (
    select
      puntuado.*,
      (v_programa.peso_citas::numeric / 100 * score_citas)
        + (v_programa.peso_ingresos::numeric / 100 * score_ingresos)
        + (v_programa.peso_clientes::numeric / 100 * score_clientes)
        + (v_programa.peso_puntualidad::numeric / 100 * score_puntualidad)
        + (v_programa.peso_calificacion::numeric / 100 * score_calificacion)
        as puntaje_final,
      rank() over (order by citas_completadas desc) as rk_citas,
      rank() over (order by ingresos_generados desc) as rk_ingresos,
      rank() over (order by clientes_distintos desc) as rk_clientes,
      rank() over (order by tasa_no_show asc) as rk_puntualidad,
      rank() over (order by calificacion_promedio desc) as rk_calificacion
    from puntuado
  )
  select
    final.barbero_id,
    final.nombre,
    rank() over (order by final.puntaje_final desc, final.ingresos_generados desc)::integer as puesto,
    round(final.puntaje_final, 2) as puntaje,
    final.citas_completadas,
    final.rk_citas::integer as puesto_citas,
    final.ingresos_generados,
    final.rk_ingresos::integer as puesto_ingresos,
    final.clientes_distintos,
    final.rk_clientes::integer as puesto_clientes,
    round(final.tasa_no_show, 4) as tasa_no_show,
    final.rk_puntualidad::integer as puesto_puntualidad,
    round(final.calificacion_promedio, 2) as calificacion_promedio,
    final.rk_calificacion::integer as puesto_calificacion
  from final
  order by puesto asc;
end;
$$;


ALTER FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) OWNER TO postgres;
