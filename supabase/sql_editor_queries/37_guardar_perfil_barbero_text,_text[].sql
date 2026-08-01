--
-- Name: guardar_perfil_barbero(text, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.guardar_perfil_barbero(p_descripcion text, p_especialidades text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  update public.barberos
  set descripcion = p_descripcion,
      especialidades = p_especialidades
  where perfil_id = auth.uid();
end;
$$;


ALTER FUNCTION public.guardar_perfil_barbero(p_descripcion text, p_especialidades text[]) OWNER TO postgres;
