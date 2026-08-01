--
-- Name: invitar_barbero_por_email(text, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.invitar_barbero_por_email(email_barbero text, id_sucursal uuid, especialidades text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_perfil_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede invitar barberos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  select id into v_perfil_id
  from public.perfiles
  where email = email_barbero;

  if v_perfil_id is null then
    raise exception 'No se encontró ningún usuario registrado con el correo proporcionado.';
  end if;

  if exists (
    select 1 from public.perfiles
    where id = v_perfil_id and barberia_id is not null and barberia_id != v_barberia_id
  ) then
    raise exception 'El usuario pertenece a otra barbería.';
  end if;

  if not exists (
    select 1 from public.sucursales
    where id = id_sucursal and barberia_id = v_barberia_id
  ) then
    raise exception 'La sucursal no pertenece a tu barbería.';
  end if;

  perform set_config('app.bypass_escalada_privilegios', 'true', true);

  update public.perfiles
  set rol = 'barbero',
      barberia_id = v_barberia_id
  where id = v_perfil_id;

  insert into public.barberos (perfil_id, sucursal_id, barberia_id, especialidades, activo)
  values (v_perfil_id, id_sucursal, v_barberia_id, especialidades, true)
  on conflict (perfil_id, sucursal_id) do update
  set especialidades = excluded.especialidades,
      activo = true;

end;
$$;


ALTER FUNCTION public.invitar_barbero_por_email(email_barbero text, id_sucursal uuid, especialidades text[]) OWNER TO postgres;
