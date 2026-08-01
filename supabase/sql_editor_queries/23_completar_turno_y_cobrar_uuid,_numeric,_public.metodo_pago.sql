--
-- Name: completar_turno_y_cobrar(uuid, numeric, public.metodo_pago); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.completar_turno_y_cobrar(p_turno_id uuid, p_monto numeric DEFAULT NULL::numeric, p_metodo public.metodo_pago DEFAULT NULL::public.metodo_pago) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_turno record;
  v_servicio record;
  v_cita record;
  v_cita_id uuid;
  v_monto numeric;
  v_metodo metodo_pago;
  v_pago_existente record;
  v_total_pagado numeric;
begin
  select * into v_turno from public.turnos where id = p_turno_id;
  if v_turno is null then
    raise exception 'Turno no encontrado.';
  end if;

  if not (
    es_superadmin()
    or (es_admin_o_superior() and v_turno.barberia_id = obtener_barberia_id_actual())
    or (
      obtener_rol_actual() = 'secretaria'
      and v_turno.sucursal_id = obtener_sucursal_id_actual()
    )
  ) then
    raise exception 'No tienes permiso para completar este turno.';
  end if;

  if v_turno.estado != 'en_atencion' or v_turno.barbero_id is null then
    raise exception 'El turno debe estar en atención con un barbero asignado.';
  end if;

  select * into v_servicio from public.servicios where id = v_turno.servicio_id;

  if v_turno.cita_id is not null then
    -- Viene de un check-in (confirmar_llegada_cita, 0016). A diferencia del
    -- walk-in puro, esta cita puede ya tener una fila en `pagos` de cuando
    -- se reservo online -- hay que reconciliar antes de tocar nada.
    --
    -- Tambien resolvemos v_cita (agregado en 0046) para conocer su
    -- precio_cobrado real (ya incluye TODOS los servicios de un combo +
    -- descuento de promo, calculado por reservar_cita) y usarlo como precio
    -- de referencia en vez del precio de un solo servicio del catalogo.
    select * into v_cita from public.citas where id = v_turno.cita_id;
    select * into v_pago_existente from public.pagos where cita_id = v_turno.cita_id;

    if v_pago_existente is null then
      -- Caso 4: nunca hubo intento de pago online para esta cita (reserva
      -- en modo "opcional" que no pago, por ejemplo). Mismo comportamiento
      -- que el walk-in de siempre: p_monto/p_metodo obligatorios, se
      -- inserta la fila de pago.
      v_monto := coalesce(v_turno.monto_precobrado, p_monto);
      v_metodo := coalesce(v_turno.metodo_precobrado, p_metodo);
      if v_monto is null or v_metodo is null then
        raise exception 'Falta el monto o el método de cobro.';
      end if;

      insert into public.pagos (barberia_id, cita_id, monto, metodo, estado)
      values (v_turno.barberia_id, v_turno.cita_id, v_monto, v_metodo, 'confirmado');

      v_total_pagado := v_monto;

    elsif v_pago_existente.estado = 'confirmado' and v_pago_existente.monto >= coalesce(v_cita.precio_cobrado, v_servicio.precio) then
      -- Caso 1: ya esta pagado completo online (QR confirmado por el
      -- admin). No hace falta cobrar nada nuevo -- p_monto/p_metodo pueden
      -- venir null, no se toca la fila de pagos. Se compara contra el
      -- precio TOTAL real de la cita (citas.precio_cobrado, cubre combos),
      -- no contra el precio de un solo servicio -- ver cabecera de 0046.
      v_total_pagado := v_pago_existente.monto;

    elsif v_pago_existente.estado = 'confirmado' then
      -- Caso 2: pago confirmado pero parcial (pago una sena online). El
      -- cajero cobra el RESTO ahora -- p_monto es SOLO lo cobrado ahora, no
      -- el total. Se ACTUALIZA la fila existente (nunca insert: violaria
      -- idx_pagos_cita_id_unico).
      v_monto := coalesce(v_turno.monto_precobrado, p_monto);
      v_metodo := coalesce(v_turno.metodo_precobrado, p_metodo);
      if v_monto is null or v_metodo is null then
        raise exception 'Falta el monto o el método de cobro.';
      end if;

      update public.pagos
      set monto = v_pago_existente.monto + v_monto, metodo = v_metodo, fecha = now()
      where id = v_pago_existente.id;

      v_total_pagado := v_pago_existente.monto + v_monto;

    else
      -- Caso 3: hay fila de pago pero no esta 'confirmado' (por_verificar,
      -- rechazado, o cualquier otro estado distinto de 'confirmado') -- el
      -- cliente nunca completo el pago online. El cajero cobra el precio
      -- completo en el local. Se ACTUALIZA la fila existente (nunca insert:
      -- violaria idx_pagos_cita_id_unico). verificado_por se limpia a null:
      -- se confirma por cobro en persona, no por verificacion de
      -- comprobante.
      v_monto := coalesce(v_turno.monto_precobrado, p_monto);
      v_metodo := coalesce(v_turno.metodo_precobrado, p_metodo);
      if v_monto is null or v_metodo is null then
        raise exception 'Falta el monto o el método de cobro.';
      end if;

      update public.pagos
      set estado = 'confirmado', monto = v_monto, metodo = v_metodo, fecha = now(),
          verificado_por = null
      where id = v_pago_existente.id;

      v_total_pagado := v_monto;
    end if;

    -- precio_cobrado siempre refleja el TOTAL pagado por la cita (incluye
    -- lo pagado online en los casos 1 y 2), no solo lo cobrado ahora.
    -- completado_por (agregado en 0050): auditoria de quien cerro la caja.
    update public.citas
    set estado = 'completada', precio_cobrado = v_total_pagado, completado_por = auth.uid()
    where id = v_turno.cita_id and estado = 'confirmada';

    if not found then
      raise exception 'La cita enlazada a este turno ya no está confirmada.';
    end if;

    v_cita_id := v_turno.cita_id;
  else
    -- Walk-in puro: sin cambios respecto a 0017/0009, salvo completado_por
    -- (0050) para que quede igual de auditable que el camino con check-in.
    v_monto := coalesce(v_turno.monto_precobrado, p_monto);
    v_metodo := coalesce(v_turno.metodo_precobrado, p_metodo);
    if v_monto is null or v_metodo is null then
      raise exception 'Falta el monto o el método de cobro.';
    end if;

    insert into public.citas (
      barberia_id, sucursal_id, barbero_id, cliente_id, cliente_walkin_id, servicio_id,
      fecha_hora, duracion_min, estado, precio_cobrado, completado_por
    ) values (
      v_turno.barberia_id, v_turno.sucursal_id, v_turno.barbero_id,
      v_turno.cliente_id, v_turno.cliente_walkin_id,
      v_turno.servicio_id, v_turno.hora_atencion, v_servicio.duracion_min,
      'completada', v_monto, auth.uid()
    ) returning id into v_cita_id;

    insert into public.pagos (barberia_id, cita_id, monto, metodo, estado)
    values (v_turno.barberia_id, v_cita_id, v_monto, v_metodo, 'confirmado');
  end if;

  update public.turnos
  set estado = 'completado', hora_completado = now(), cita_id = v_cita_id
  where id = p_turno_id and estado = 'en_atencion';

  if not found then
    raise exception 'El turno ya no está en atención (lo modificó otra operación).';
  end if;

  return v_cita_id;
end;
$$;


ALTER FUNCTION public.completar_turno_y_cobrar(p_turno_id uuid, p_monto numeric, p_metodo public.metodo_pago) OWNER TO postgres;
