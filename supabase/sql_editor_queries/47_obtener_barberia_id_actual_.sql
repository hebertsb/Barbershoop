--
-- Name: obtener_barberia_id_actual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_barberia_id_actual() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select barberia_id from public.perfiles where id = auth.uid();
$$;


ALTER FUNCTION public.obtener_barberia_id_actual() OWNER TO postgres;
