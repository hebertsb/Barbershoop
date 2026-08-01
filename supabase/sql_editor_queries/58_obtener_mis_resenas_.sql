--
-- Name: obtener_mis_resenas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_mis_resenas() RETURNS TABLE(id uuid, cliente_nombre text, calificacion integer, comentario text, creado_en timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select r.id, p.nombre, r.calificacion, r.comentario, r.creado_en
  from public.resenas r
  join public.perfiles p on p.id = r.cliente_id
  where r.barbero_id in (
    select id from public.barberos where perfil_id = auth.uid()
  )
  order by r.creado_en desc;
$$;


ALTER FUNCTION public.obtener_mis_resenas() OWNER TO postgres;
