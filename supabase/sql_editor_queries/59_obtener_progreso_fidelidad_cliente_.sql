--
-- Name: obtener_progreso_fidelidad_cliente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_progreso_fidelidad_cliente() RETURNS TABLE(programa_id uuid, titulo text, progreso_actual integer, meta_citas integer, puede_reclamar boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    return;
  end if;

  return query
  with progreso as (
    select
      pf.id as p_id,
      pf.titulo as p_titulo,
      pf.meta_citas as p_meta,
      coalesce((
        select count(*)::integer
        from public.citas c
        where c.cliente_id = auth.uid()
          and c.estado = 'completada'
          and c.servicio_id in (
            select jsonb_array_elements_text(pf.servicios_ids)::uuid
          )
          and c.fecha_hora > coalesce(
            (
              select max(rf.reclamado_en)
              from public.reclamaciones_fidelidad rf
              where rf.programa_id = pf.id and rf.cliente_id = auth.uid()
            ),
            pf.creado_en
          )
      ), 0) as p_progreso
    from public.programas_fidelidad pf
    where pf.barberia_id = v_barberia_id
      and pf.activo = true
      and (pf.fecha_inicio is null or pf.fecha_inicio <= current_date)
      and (pf.fecha_fin is null or pf.fecha_fin >= current_date)
  )
  select
    p_id,
    p_titulo,
    p_progreso,
    p_meta,
    p_progreso >= p_meta
  from progreso;
end;
$$;


ALTER FUNCTION public.obtener_progreso_fidelidad_cliente() OWNER TO postgres;
