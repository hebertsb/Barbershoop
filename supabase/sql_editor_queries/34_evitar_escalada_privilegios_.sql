--
-- Name: evitar_escalada_privilegios(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.evitar_escalada_privilegios() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
begin
  if new.rol is distinct from old.rol and not es_superadmin() then
    if not (
      (
        new.rol in ('barbero', 'secretaria')
        or (old.rol in ('barbero', 'secretaria') and new.rol = 'cliente')
      )
      and coalesce(current_setting('app.bypass_escalada_privilegios', true), 'false') = 'true'
    ) then
      raise exception 'Solo un superadmin puede cambiar el rol.';
    end if;
  end if;
  if new.barberia_id is distinct from old.barberia_id
     and old.barberia_id is not null
     and not es_superadmin() then
    raise exception 'No puedes cambiar de barbería una vez asignada.';
  end if;
  return new;
end;
$$;


ALTER FUNCTION public.evitar_escalada_privilegios() OWNER TO postgres;
