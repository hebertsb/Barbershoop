--
-- Name: cancelar_turno(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancelar_turno(p_turno_id uuid) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_turno turnos;
begin
  select * into v_turno from public.turnos where id = p_turno_id;
  if v_turno is null then
    raise exception 'Turno no encontrado.';
  end if;

  perform validar_permiso_turno(v_turno.sucursal_id);

  if v_turno.estado not in ('esperando', 'en_atencion') then
    raise exception 'Este turno ya no se puede cancelar.';
  end if;

  update public.turnos set estado = 'cancelado' where id = p_turno_id
  returning * into v_turno;

  if v_turno.cita_id is not null then
    update public.citas set estado = 'cancelada', cancelado_por = auth.uid()
    where id = v_turno.cita_id and estado = 'confirmada';
  end if;

  return v_turno;
end;
$$;


ALTER FUNCTION public.cancelar_turno(p_turno_id uuid) OWNER TO postgres;
