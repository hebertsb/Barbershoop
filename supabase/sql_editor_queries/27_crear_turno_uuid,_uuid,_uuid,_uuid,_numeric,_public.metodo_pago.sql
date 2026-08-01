--
-- Name: crear_turno(uuid, uuid, uuid, uuid, numeric, public.metodo_pago); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric DEFAULT NULL::numeric, p_metodo_precobrado public.metodo_pago DEFAULT NULL::public.metodo_pago) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_numero integer;
  v_turno turnos;
begin
  v_barberia_id := validar_permiso_turno(p_sucursal_id);

  perform pg_advisory_xact_lock(hashtext(p_sucursal_id::text || current_date::text));

  select coalesce(max(numero), 0) + 1 into v_numero
  from public.turnos
  where sucursal_id = p_sucursal_id and hora_llegada::date = current_date;

  insert into public.turnos (
    barberia_id, sucursal_id, numero, cliente_id, cliente_walkin_id, servicio_id,
    monto_precobrado, metodo_precobrado
  ) values (
    v_barberia_id, p_sucursal_id, v_numero, p_cliente_id, p_cliente_walkin_id, p_servicio_id,
    p_monto_precobrado, p_metodo_precobrado
  ) returning * into v_turno;

  return v_turno;
end;
$$;


ALTER FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) OWNER TO postgres;
