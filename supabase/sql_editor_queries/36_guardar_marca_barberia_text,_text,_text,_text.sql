--
-- Name: guardar_marca_barberia(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.guardar_marca_barberia(p_nombre text, p_slogan text, p_url_logo text, p_color_acento_hex text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_barberia barberias;
begin
  if not es_admin_o_superior() then
    raise exception 'No tenés permiso para editar la marca de la barbería.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  update public.barberias
  set nombre = p_nombre,
      slogan = p_slogan,
      url_logo = p_url_logo
  where id = v_barberia_id
  returning * into v_barberia;

  if not found then
    raise exception 'Barbería no encontrada.';
  end if;

  insert into public.configuraciones_barberia (barberia_id, clave, valor)
  values (v_barberia_id, 'color_acento', jsonb_build_object('hex', p_color_acento_hex))
  on conflict (barberia_id, clave) do update set valor = excluded.valor;
end;
$$;


ALTER FUNCTION public.guardar_marca_barberia(p_nombre text, p_slogan text, p_url_logo text, p_color_acento_hex text) OWNER TO postgres;
