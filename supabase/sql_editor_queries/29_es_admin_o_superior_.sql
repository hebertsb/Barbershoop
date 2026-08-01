--
-- Name: es_admin_o_superior(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_admin_o_superior() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_rol_actual() in ('admin', 'superadmin');
$$;


ALTER FUNCTION public.es_admin_o_superior() OWNER TO postgres;
