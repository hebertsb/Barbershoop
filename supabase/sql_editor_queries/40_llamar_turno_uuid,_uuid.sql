--
-- Name: llamar_turno(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_turno record;
  v_servicio record;
  v_fin_estimado timestamptz;
begin
  select * into v_turno from public.turnos where id = p_turno_id;
  if v_turno is null then
    raise exception 'Turno no encontrado.';
  end if;

  if not (
    es_superadmin()
    or (es_admin_o_superior() and v_turno.barberia_id = obtener_barberia_id_actual())
    or (
      obtener_rol_actual() = 'secretaria'
      and v_turno.sucursal_id = obtener_sucursal_id_actual()
    )
  ) then
    raise exception 'No tienes permiso para llamar este turno.';
  end if;

  if v_turno.estado != 'esperando' then
    raise exception 'El turno debe estar esperando para poder llamarlo.';
  end if;

  select * into v_servicio from public.servicios where id = v_turno.servicio_id;
  v_fin_estimado := now() + (v_servicio.duracion_min || ' minutes')::interval;

  if exists (
    select 1 from public.citas c
    where c.barbero_id = p_barbero_id
      and c.estado in ('pendiente', 'confirmada')
      and (v_turno.cita_id is null or c.id != v_turno.cita_id)
      and now() < c.fecha_hora + (c.duracion_min || ' minutes')::interval
      and v_fin_estimado > c.fecha_hora
  ) then
    raise exception 'Ese barbero tiene una cita reservada pronto, no está disponible.';
  end if;

  if exists (
    select 1 from public.turnos t2
    where t2.barbero_id = p_barbero_id
      and t2.estado = 'en_atencion'
  ) then
    raise exception 'Ese barbero ya está atendiendo otro turno, no está disponible.';
  end if;

  update public.turnos
  set estado = 'en_atencion', barbero_id = p_barbero_id, hora_atencion = now()
  where id = p_turno_id and estado = 'esperando';

  if not found then
    raise exception 'El turno ya no está esperando (lo modificó otra operación).';
  end if;
end;
$$;


ALTER FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) OWNER TO postgres;
