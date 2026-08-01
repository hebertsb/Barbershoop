--
-- Name: obtener_accesos_rapidos_top(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_accesos_rapidos_top(p_limite integer DEFAULT 4) RETURNS TABLE(ruta text, usos bigint)
    LANGUAGE sql STABLE
    AS $$
  select a.ruta, count(*) as usos
  from accesos_admin_uso a
  where a.perfil_id = auth.uid()
    and a.creado_en >= now() - interval '30 days'
  group by a.ruta
  order by usos desc, a.ruta asc
  limit p_limite;
$$;


ALTER FUNCTION public.obtener_accesos_rapidos_top(p_limite integer) OWNER TO postgres;
