--
-- Name: es_cliente_o_superior(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_barberia_id_actual() = p_barberia_id or es_superadmin();
$$;


ALTER FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) OWNER TO postgres;
