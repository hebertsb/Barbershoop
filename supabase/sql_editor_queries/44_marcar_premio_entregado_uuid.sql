--
-- Name: marcar_premio_entregado(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.marcar_premio_entregado(p_programa_id uuid) RETURNS public.programas_ranking_barberos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_programa programas_ranking_barberos;
begin
  if not es_admin_o_superior() then
    raise exception 'No tienes permiso para esta acción.';
  end if;

  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa is null or v_programa.barberia_id != obtener_barberia_id_actual() then
    raise exception 'Programa no encontrado.';
  end if;
  if v_programa.estado != 'cerrado' then
    raise exception 'El programa todavía no está cerrado.';
  end if;

  update public.programas_ranking_barberos
  set premio_entregado = true
  where id = p_programa_id
  returning * into v_programa;

  return v_programa;
end;
$$;


ALTER FUNCTION public.marcar_premio_entregado(p_programa_id uuid) OWNER TO postgres;
