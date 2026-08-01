--
-- Name: es_admin_o_superior_o_secretaria(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_admin_o_superior_o_secretaria() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_rol_actual() in ('admin', 'superadmin', 'secretaria');
$$;


ALTER FUNCTION public.es_admin_o_superior_o_secretaria() OWNER TO postgres;
