--
-- Name: es_superadmin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_superadmin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_rol_actual() = 'superadmin';
$$;


ALTER FUNCTION public.es_superadmin() OWNER TO postgres;
