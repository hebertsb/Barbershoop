--
-- Name: marcar_cita_no_asistio(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) RETURNS public.citas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
begin
  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null then
    raise exception 'Cita no encontrada.';
  end if;

  perform validar_permiso_turno(v_cita.sucursal_id);

  if v_cita.estado != 'pendiente' then
    raise exception 'Esta cita ya no está pendiente.';
  end if;

  if v_cita.fecha_hora > now() then
    raise exception 'Todavía no es la hora de esta cita.';
  end if;

  update public.citas set estado = 'no_asistio', cancelado_por = auth.uid() where id = p_cita_id
  returning * into v_cita;

  return v_cita;
end;
$$;


ALTER FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) OWNER TO postgres;
