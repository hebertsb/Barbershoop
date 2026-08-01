--
-- Name: obtener_barberos_publicos(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_barberos_publicos(p_sucursal_id uuid DEFAULT NULL::uuid) RETURNS TABLE(id uuid, perfil_id uuid, sucursal_id uuid, barberia_id uuid, especialidades text[], activo boolean, nombre_perfil text, url_foto_perfil text, nivel text, descripcion text, telefono_perfil text, calificacion_promedio numeric, calificacion_cantidad integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    b.id, b.perfil_id, b.sucursal_id, b.barberia_id, b.especialidades, b.activo,
    p.nombre, p.url_foto, b.nivel, b.descripcion, p.telefono,
    round(avg(r.calificacion), 1) as calificacion_promedio,
    count(r.id)::integer as calificacion_cantidad
  from public.barberos b
  join public.perfiles p on p.id = b.perfil_id
  left join public.resenas r on r.barbero_id = b.id
  where b.barberia_id = obtener_barberia_id_actual()
    and (p_sucursal_id is null or b.sucursal_id = p_sucursal_id)
    and b.activo = true
  group by b.id, b.perfil_id, b.sucursal_id, b.barberia_id, b.especialidades, b.activo,
    p.nombre, p.url_foto, b.nivel, b.descripcion, p.telefono;
$$;


ALTER FUNCTION public.obtener_barberos_publicos(p_sucursal_id uuid) OWNER TO postgres;
