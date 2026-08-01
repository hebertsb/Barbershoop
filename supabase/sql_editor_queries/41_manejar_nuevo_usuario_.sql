--
-- Name: manejar_nuevo_usuario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.manejar_nuevo_usuario() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  insert into public.perfiles (id, email, nombre, url_foto)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;


ALTER FUNCTION public.manejar_nuevo_usuario() OWNER TO postgres;
