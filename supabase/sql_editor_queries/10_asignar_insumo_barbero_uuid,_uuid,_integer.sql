--
-- Name: asignar_insumo_barbero(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.asignar_insumo_barbero(p_insumo_id uuid, p_barbero_id uuid, p_cantidad integer) RETURNS public.insumos_barbero
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_insumo insumos;
  v_fila insumos_barbero;
begin
  if not es_admin_o_superior() then
    raise exception 'No tenés permiso para asignar insumos.';
  end if;

  if p_cantidad <= 0 then
    raise exception 'La cantidad debe ser mayor a cero.';
  end if;

  select * into v_insumo
  from public.insumos
  where id = p_insumo_id and barberia_id = obtener_barberia_id_actual();

  if v_insumo is null then
    raise exception 'Insumo no encontrado.';
  end if;

  if not exists (
    select 1 from public.barberos
    where id = p_barbero_id and barberia_id = v_insumo.barberia_id
  ) then
    raise exception 'Barbero no encontrado.';
  end if;

  update public.insumos
  set stock = stock - p_cantidad
  where id = p_insumo_id and stock >= p_cantidad;

  if not found then
    raise exception 'No hay suficiente stock disponible.';
  end if;

  insert into public.insumos_barbero (barberia_id, barbero_id, insumo_id, cantidad_asignada)
  values (v_insumo.barberia_id, p_barbero_id, p_insumo_id, p_cantidad)
  on conflict (barbero_id, insumo_id)
  do update set cantidad_asignada = insumos_barbero.cantidad_asignada + excluded.cantidad_asignada
  returning * into v_fila;

  return v_fila;
end;
$$;


ALTER FUNCTION public.asignar_insumo_barbero(p_insumo_id uuid, p_barbero_id uuid, p_cantidad integer) OWNER TO postgres;
