--
-- Name: cerrar_programa_ranking(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) RETURNS public.programas_ranking_barberos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_programa programas_ranking_barberos;
  v_ganador uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'No tienes permiso para cerrar este programa.';
  end if;

  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa is null or v_programa.barberia_id != obtener_barberia_id_actual() then
    raise exception 'Programa no encontrado.';
  end if;
  if v_programa.fecha_fin > current_date then
    raise exception 'Todavía no llegó la fecha fin del programa.';
  end if;

  perform pg_advisory_xact_lock(hashtext('cerrar_ranking:' || p_programa_id::text));

  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa.estado != 'activo' then
    raise exception 'Este programa ya está cerrado.';
  end if;

  insert into public.insignias_ranking_barberos (programa_id, barbero_id, puesto)
  select p_programa_id, r.barbero_id, r.puesto
  from public.obtener_ranking_barberos(p_programa_id) r
  where r.puesto <= 3
  on conflict (programa_id, barbero_id) do nothing;

  select r.barbero_id into v_ganador
  from public.obtener_ranking_barberos(p_programa_id) r
  where r.puesto = 1
  limit 1;

  if v_ganador is null then
    raise exception 'No hay barberos con actividad en este período para premiar.';
  end if;

  update public.programas_ranking_barberos
  set estado = 'cerrado',
      barbero_ganador_id = v_ganador,
      cerrado_en = now(),
      cerrado_por = auth.uid()
  where id = p_programa_id
  returning * into v_programa;

  return v_programa;
end;
$$;


ALTER FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) OWNER TO postgres;
