--
-- Name: confirmar_llegada_cita(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita record;
  v_barberia_id uuid;
  v_numero integer;
  v_turno turnos;
begin
  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null then
    raise exception 'Cita no encontrada.';
  end if;

  v_barberia_id := validar_permiso_turno(v_cita.sucursal_id);

  perform pg_advisory_xact_lock(hashtext(v_cita.sucursal_id::text || current_date::text));

  update public.citas set estado = 'confirmada'
  where id = p_cita_id and estado = 'pendiente'
  returning * into v_cita;

  if not found then
    raise exception 'Esta cita no está pendiente de check-in.';
  end if;

  select coalesce(max(numero), 0) + 1 into v_numero
  from public.turnos
  where sucursal_id = v_cita.sucursal_id and hora_llegada::date = current_date;

  insert into public.turnos (
    barberia_id, sucursal_id, numero, cliente_id, cliente_walkin_id, servicio_id,
    barbero_id, cita_id
  ) values (
    v_barberia_id, v_cita.sucursal_id, v_numero, v_cita.cliente_id, v_cita.cliente_walkin_id,
    v_cita.servicio_id, v_cita.barbero_id, v_cita.id
  ) returning * into v_turno;

  return v_turno;
end;
$$;


ALTER FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) OWNER TO postgres;
