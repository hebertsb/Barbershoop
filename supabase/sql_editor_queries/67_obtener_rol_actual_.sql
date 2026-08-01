--
-- Name: obtener_rol_actual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_rol_actual() RETURNS public.rol_usuario
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select rol from public.perfiles where id = auth.uid();
$$;


ALTER FUNCTION public.obtener_rol_actual() OWNER TO postgres;
