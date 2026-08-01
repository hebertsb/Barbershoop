--
-- Name: crear_turno_walkin(uuid, uuid, text, text, numeric, public.metodo_pago); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric DEFAULT NULL::numeric, p_metodo_precobrado public.metodo_pago DEFAULT NULL::public.metodo_pago) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_cliente_walkin_id uuid;
begin
  v_barberia_id := validar_permiso_turno(p_sucursal_id);

  insert into public.clientes_walkin (barberia_id, nombre, telefono)
  values (v_barberia_id, p_nombre, p_telefono)
  on conflict (barberia_id, telefono)
  do update set nombre = excluded.nombre
  returning id into v_cliente_walkin_id;

  return crear_turno(
    p_sucursal_id, p_servicio_id, null, v_cliente_walkin_id,
    p_monto_precobrado, p_metodo_precobrado
  );
end;
$$;


ALTER FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) OWNER TO postgres;
