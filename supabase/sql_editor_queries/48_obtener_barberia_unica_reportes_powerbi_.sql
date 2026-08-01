--
-- Name: obtener_barberia_unica_reportes_powerbi(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_barberia_unica_reportes_powerbi() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select id from public.barberias order by creado_en asc limit 1;
$$;


ALTER FUNCTION public.obtener_barberia_unica_reportes_powerbi() OWNER TO postgres;
