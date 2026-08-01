--
-- Name: cancelar_cita_cliente(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) RETURNS public.citas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
  v_minutos integer;
  v_mensaje text;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null or v_cita.cliente_id is distinct from auth.uid() then
    raise exception 'Cita no encontrada.';
  end if;

  if v_cita.estado = 'confirmada' then
    raise exception 'Ya hiciste check-in para esta cita, para cancelarla hablá con el local.';
  elsif v_cita.estado != 'pendiente' then
    raise exception 'Esta cita ya no se puede cancelar.';
  end if;

  v_minutos := coalesce(
    (
      select (cb.valor ->> 'minutos')::int
      from public.configuraciones_barberia cb
      where cb.barberia_id = v_cita.barberia_id
        and cb.clave = 'minutos_minimos_cancelacion_cliente'
    ),
    120
  );

  if v_cita.fecha_hora - now() < (v_minutos || ' minutes')::interval then
    v_mensaje := 'Faltan menos de ' || v_minutos || ' minutos para tu cita, contactá al local para cancelarla.';
    raise exception '%', v_mensaje;
  end if;

  update public.citas
  set estado = 'cancelada', cancelado_por = auth.uid()
  where id = p_cita_id and cliente_id = auth.uid() and estado = 'pendiente'
  returning * into v_cita;

  if not found then
    raise exception 'Esta cita ya no se puede cancelar.';
  end if;

  return v_cita;
end;
$$;


ALTER FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) OWNER TO postgres;
