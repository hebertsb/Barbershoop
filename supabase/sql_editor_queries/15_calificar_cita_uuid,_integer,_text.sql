--
-- Name: calificar_cita(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) RETURNS public.resenas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
  v_resena resenas;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null or v_cita.cliente_id is distinct from auth.uid() then
    raise exception 'Cita no encontrada.';
  end if;

  if v_cita.estado != 'completada' then
    raise exception 'Todavía no se puede calificar esta cita.';
  end if;

  if p_calificacion < 1 or p_calificacion > 5 then
    raise exception 'La calificación debe ser entre 1 y 5.';
  end if;

  if exists (select 1 from public.resenas where cita_id = p_cita_id) then
    raise exception 'Ya calificaste esta cita.';
  end if;

  insert into public.resenas (barberia_id, cita_id, cliente_id, barbero_id, calificacion, comentario)
  values (v_cita.barberia_id, p_cita_id, auth.uid(), v_cita.barbero_id, p_calificacion, p_comentario)
  returning * into v_resena;

  return v_resena;
end;
$$;


ALTER FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) OWNER TO postgres;
