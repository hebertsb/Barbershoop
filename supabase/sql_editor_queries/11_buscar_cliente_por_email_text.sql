--
-- Name: buscar_cliente_por_email(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.buscar_cliente_por_email(p_email text) RETURNS TABLE(id uuid, nombre text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior_o_secretaria() then
    raise exception 'No tienes permiso para buscar clientes.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();

  return query
    select p.id, p.nombre
    from public.perfiles p
    where p.email = p_email
      and (p.barberia_id is null or p.barberia_id = v_barberia_id);
end;
$$;


ALTER FUNCTION public.buscar_cliente_por_email(p_email text) OWNER TO postgres;
