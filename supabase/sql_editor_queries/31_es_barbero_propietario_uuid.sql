--
-- Name: es_barbero_propietario(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_barbero_propietario(id_barbero uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from public.barberos b
    where b.id = id_barbero and b.perfil_id = auth.uid()
  );
$$;


ALTER FUNCTION public.es_barbero_propietario(id_barbero uuid) OWNER TO postgres;
