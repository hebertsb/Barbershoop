--
-- Name: confirmar_pago(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.confirmar_pago(p_pago_id uuid) RETURNS public.pagos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_pago pagos;
begin
  if not (
    es_superadmin()
    or (
      es_admin_o_superior()
      and exists (
        select 1 from public.pagos p
        where p.id = p_pago_id and p.barberia_id = obtener_barberia_id_actual()
      )
    )
  ) then
    raise exception 'No tienes permiso para verificar este pago.';
  end if;

  update public.pagos
  set estado = 'confirmado', verificado_por = auth.uid()
  where id = p_pago_id and estado = 'por_verificar'
  returning * into v_pago;

  if not found then
    raise exception 'Este pago no está pendiente de verificación.';
  end if;

  return v_pago;
end;
$$;


ALTER FUNCTION public.confirmar_pago(p_pago_id uuid) OWNER TO postgres;
