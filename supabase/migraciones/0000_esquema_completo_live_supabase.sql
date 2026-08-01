--
-- PostgreSQL database dump
--

\restrict RNxmZqS4JSyP1lOqXtX8oZEcLAUTQHnAjvKSGRyuRd7wPGu9wikZAzHxXcQRNYF

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: estado_cita; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_cita AS ENUM (
    'pendiente',
    'confirmada',
    'completada',
    'cancelada',
    'no_asistio'
);


ALTER TYPE public.estado_cita OWNER TO postgres;

--
-- Name: estado_pago; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_pago AS ENUM (
    'pendiente',
    'por_verificar',
    'confirmado',
    'rechazado'
);


ALTER TYPE public.estado_pago OWNER TO postgres;

--
-- Name: estado_reporte_insumo; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_reporte_insumo AS ENUM (
    'pendiente',
    'atendido',
    'rechazado'
);


ALTER TYPE public.estado_reporte_insumo OWNER TO postgres;

--
-- Name: estado_turno; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_turno AS ENUM (
    'esperando',
    'en_atencion',
    'completado',
    'cancelado'
);


ALTER TYPE public.estado_turno OWNER TO postgres;

--
-- Name: metodo_pago; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.metodo_pago AS ENUM (
    'efectivo',
    'qr_manual',
    'pasarela'
);


ALTER TYPE public.metodo_pago OWNER TO postgres;

--
-- Name: rol_usuario; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.rol_usuario AS ENUM (
    'cliente',
    'barbero',
    'admin',
    'superadmin',
    'secretaria'
);


ALTER TYPE public.rol_usuario OWNER TO postgres;

--
-- Name: tipo_reporte_insumo; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_reporte_insumo AS ENUM (
    'danado',
    'agotado',
    'perdido'
);


ALTER TYPE public.tipo_reporte_insumo OWNER TO postgres;

--
-- Name: actualizar_columna_actualizado_en(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_columna_actualizado_en() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;


ALTER FUNCTION public.actualizar_columna_actualizado_en() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: insumos_barbero; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insumos_barbero (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    insumo_id uuid NOT NULL,
    cantidad_asignada integer DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT insumos_barbero_cantidad_asignada_check CHECK ((cantidad_asignada >= 0))
);


ALTER TABLE public.insumos_barbero OWNER TO postgres;

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

--
-- Name: buscar_cliente_por_email(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.buscar_cliente_por_email(p_email text) RETURNS TABLE(id uuid, nombre text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior_o_secretaria() then
    raise exception 'No tienes permiso para buscar clientes.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();

  return query
    select p.id, p.nombre
    from public.perfiles p
    where p.email = p_email
      and (p.barberia_id is null or p.barberia_id = v_barberia_id);
end;
$$;


ALTER FUNCTION public.buscar_cliente_por_email(p_email text) OWNER TO postgres;

--
-- Name: calcular_huecos_libres_hoy(uuid, integer, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid DEFAULT NULL::uuid) RETURNS TABLE(barbero_id uuid, hora_inicio timestamp with time zone, hora_fin timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_hoy date;
  v_dia_semana smallint;
  v_barbero record;
  v_horario record;
  v_inicio_jornada timestamptz;
  v_fin_jornada timestamptz;
  v_cursor timestamptz;
  v_turno record;
  v_dur_turno integer;
  v_libre_desde timestamptz;
  v_cita_activa record;
  v_ocupado record;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar huecos de esta sucursal.';
  end if;

  if p_duracion_min is null or p_duracion_min <= 0 then
    return;
  end if;

  -- "Hoy" y "ahora" en hora local de Bolivia (mismo criterio que 0013: la
  -- hora guardada en horarios_barbero es hora local, no UTC).
  v_hoy := (now() at time zone 'America/La_Paz')::date;
  v_dia_semana := extract(dow from v_hoy)::smallint;

  for v_barbero in
    select b.id
    from public.barberos b
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
  loop
    -- Paso 1: horario del barbero para hoy. Sin horario cargado ese dia =
    -- sin huecos para este barbero.
    select h.hora_inicio, h.hora_fin into v_horario
    from public.horarios_barbero h
    where h.barbero_id = v_barbero.id
      and h.dia_semana = v_dia_semana
    limit 1;

    if not found then
      continue;
    end if;

    v_inicio_jornada := ((v_hoy + v_horario.hora_inicio) at time zone 'America/La_Paz');
    v_fin_jornada := ((v_hoy + v_horario.hora_fin) at time zone 'America/La_Paz');

    -- Paso 2: cursor arranca en el mayor entre ahora y el inicio de jornada.
    v_cursor := greatest(now(), v_inicio_jornada);
    v_libre_desde := null;

    -- Paso 3: turno en_atencion ahora mismo (a lo sumo uno por barbero --
    -- llamar_turno, 0018, ya impide asignar un segundo turno en_atencion al
    -- mismo barbero mientras el primero sigue abierto).
    select t.hora_atencion, t.servicio_id into v_turno
    from public.turnos t
    where t.barbero_id = v_barbero.id
      and t.estado = 'en_atencion'
    limit 1;

    if found then
      if v_turno.hora_atencion is not null then
        select sv.duracion_min into v_dur_turno
        from public.servicios sv
        where sv.id = v_turno.servicio_id;

        if found then
          v_libre_desde := v_turno.hora_atencion + (v_dur_turno || ' minutes')::interval;
        end if;
      end if;

      -- Fail-safe: no se pudo estimar cuando termina (falta hora_atencion o
      -- no se encontro el servicio del turno) -> sin huecos hoy para este
      -- barbero, igual que el Dart.
      if v_libre_desde is null then
        continue;
      end if;
    else
      -- Paso 4: sin turno en curso, pero puede haber una cita
      -- pendiente/confirmada activa justo ahora (rol equivalente al turno
      -- en_atencion en el Dart).
      select c.fecha_hora, c.duracion_min into v_cita_activa
      from public.citas c
      where c.barbero_id = v_barbero.id
        and c.estado in ('pendiente', 'confirmada')
        and c.fecha_hora <= now()
        and now() < c.fecha_hora + (c.duracion_min || ' minutes')::interval
      limit 1;

      if found then
        v_libre_desde := v_cita_activa.fecha_hora + (v_cita_activa.duracion_min || ' minutes')::interval;
      end if;
    end if;

    if v_libre_desde is not null and v_libre_desde > v_cursor then
      v_cursor := v_libre_desde;
    end if;

    -- Paso 5: jornada ya cerrada (o por cerrar) para este barbero.
    if v_cursor >= v_fin_jornada then
      continue;
    end if;

    -- Paso 6/7: recorre las citas pendientes/confirmadas que se solapan con
    -- [cursor, fin_jornada), generando huecos entre ellas, y emite solo los
    -- que alcanzan para p_duracion_min.
    for v_ocupado in
      select c.fecha_hora as inicio,
             c.fecha_hora + (c.duracion_min || ' minutes')::interval as fin
      from public.citas c
      where c.barbero_id = v_barbero.id
        and c.estado in ('pendiente', 'confirmada')
        and c.fecha_hora + (c.duracion_min || ' minutes')::interval > v_cursor
        and c.fecha_hora < v_fin_jornada
      order by c.fecha_hora
    loop
      if v_ocupado.inicio > v_cursor
         and (v_ocupado.inicio - v_cursor) >= (p_duracion_min || ' minutes')::interval
      then
        barbero_id := v_barbero.id;
        hora_inicio := v_cursor;
        hora_fin := v_ocupado.inicio;
        return next;
      end if;
      if v_ocupado.fin > v_cursor then
        v_cursor := v_ocupado.fin;
      end if;
    end loop;

    if v_cursor < v_fin_jornada
       and (v_fin_jornada - v_cursor) >= (p_duracion_min || ' minutes')::interval
    then
      barbero_id := v_barbero.id;
      hora_inicio := v_cursor;
      hora_fin := v_fin_jornada;
      return next;
    end if;
  end loop;
end;
$$;


ALTER FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid) OWNER TO postgres;

--
-- Name: calcular_huecos_libres_hoy(uuid, integer, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid DEFAULT NULL::uuid, p_promocion_id uuid DEFAULT NULL::uuid) RETURNS TABLE(barbero_id uuid, hora_inicio timestamp with time zone, hora_fin timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_efectiva integer;
  v_promo record;
  v_duracion_combo integer;
  v_hoy date;
  v_dia_semana smallint;
  v_barbero record;
  v_horario record;
  v_inicio_jornada timestamptz;
  v_fin_jornada timestamptz;
  v_cursor timestamptz;
  v_turno record;
  v_dur_turno integer;
  v_libre_desde timestamptz;
  v_cita_activa record;
  v_ocupado record;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar huecos de esta sucursal.';
  end if;

  -- Si la reserva es por una promocion combo (2+ servicios), la duracion
  -- del bloque es la suma de TODOS los servicios del combo, no la de un
  -- solo servicio -- mismo criterio que reservar_cita (0040). Se ignora
  -- silenciosamente si la promo no existe/no es combo (queda p_duracion_min
  -- tal cual, comportamiento identico al de antes de esta migracion).
  v_duracion_efectiva := p_duracion_min;

  if p_promocion_id is not null then
    select * into v_promo
    from public.promociones
    where id = p_promocion_id
      and barberia_id = v_barberia_id;

    if v_promo is not null
       and v_promo.servicios_ids is not null
       and jsonb_array_length(v_promo.servicios_ids) > 1
    then
      select coalesce(sum(sv.duracion_min), 0) into v_duracion_combo
      from public.servicios sv
      where sv.id in (
        select jsonb_array_elements_text(v_promo.servicios_ids)::uuid
      )
      and sv.barberia_id = v_barberia_id;

      if v_duracion_combo > 0 then
        v_duracion_efectiva := v_duracion_combo;
      end if;
    end if;
  end if;

  if v_duracion_efectiva is null or v_duracion_efectiva <= 0 then
    return;
  end if;

  -- "Hoy" y "ahora" en hora local de Bolivia (mismo criterio que 0013: la
  -- hora guardada en horarios_barbero es hora local, no UTC).
  v_hoy := (now() at time zone 'America/La_Paz')::date;
  v_dia_semana := extract(dow from v_hoy)::smallint;

  for v_barbero in
    select b.id
    from public.barberos b
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
  loop
    -- Paso 1: horario del barbero para hoy. Sin horario cargado ese dia =
    -- sin huecos para este barbero.
    select h.hora_inicio, h.hora_fin into v_horario
    from public.horarios_barbero h
    where h.barbero_id = v_barbero.id
      and h.dia_semana = v_dia_semana
    limit 1;

    if not found then
      continue;
    end if;

    v_inicio_jornada := ((v_hoy + v_horario.hora_inicio) at time zone 'America/La_Paz');
    v_fin_jornada := ((v_hoy + v_horario.hora_fin) at time zone 'America/La_Paz');

    -- Paso 2: cursor arranca en el mayor entre ahora y el inicio de jornada.
    v_cursor := greatest(now(), v_inicio_jornada);
    v_libre_desde := null;

    -- Paso 3: turno en_atencion ahora mismo (a lo sumo uno por barbero --
    -- llamar_turno, 0018, ya impide asignar un segundo turno en_atencion al
    -- mismo barbero mientras el primero sigue abierto).
    select t.hora_atencion, t.servicio_id into v_turno
    from public.turnos t
    where t.barbero_id = v_barbero.id
      and t.estado = 'en_atencion'
    limit 1;

    if found then
      if v_turno.hora_atencion is not null then
        select sv.duracion_min into v_dur_turno
        from public.servicios sv
        where sv.id = v_turno.servicio_id;

        if found then
          v_libre_desde := v_turno.hora_atencion + (v_dur_turno || ' minutes')::interval;
        end if;
      end if;

      -- Fail-safe: no se pudo estimar cuando termina (falta hora_atencion o
      -- no se encontro el servicio del turno) -> sin huecos hoy para este
      -- barbero, igual que el Dart.
      if v_libre_desde is null then
        continue;
      end if;
    else
      -- Paso 4: sin turno en curso, pero puede haber una cita
      -- pendiente/confirmada activa justo ahora (rol equivalente al turno
      -- en_atencion en el Dart).
      select c.fecha_hora, c.duracion_min into v_cita_activa
      from public.citas c
      where c.barbero_id = v_barbero.id
        and c.estado in ('pendiente', 'confirmada')
        and c.fecha_hora <= now()
        and now() < c.fecha_hora + (c.duracion_min || ' minutes')::interval
      limit 1;

      if found then
        v_libre_desde := v_cita_activa.fecha_hora + (v_cita_activa.duracion_min || ' minutes')::interval;
      end if;
    end if;

    if v_libre_desde is not null and v_libre_desde > v_cursor then
      v_cursor := v_libre_desde;
    end if;

    -- Paso 5: jornada ya cerrada (o por cerrar) para este barbero.
    if v_cursor >= v_fin_jornada then
      continue;
    end if;

    -- Paso 6/7: recorre las citas pendientes/confirmadas que se solapan con
    -- [cursor, fin_jornada), generando huecos entre ellas, y emite solo los
    -- que alcanzan para v_duracion_efectiva.
    for v_ocupado in
      select c.fecha_hora as inicio,
             c.fecha_hora + (c.duracion_min || ' minutes')::interval as fin
      from public.citas c
      where c.barbero_id = v_barbero.id
        and c.estado in ('pendiente', 'confirmada')
        and c.fecha_hora + (c.duracion_min || ' minutes')::interval > v_cursor
        and c.fecha_hora < v_fin_jornada
      order by c.fecha_hora
    loop
      if v_ocupado.inicio > v_cursor
         and (v_ocupado.inicio - v_cursor) >= (v_duracion_efectiva || ' minutes')::interval
      then
        barbero_id := v_barbero.id;
        hora_inicio := v_cursor;
        hora_fin := v_ocupado.inicio;
        return next;
      end if;
      if v_ocupado.fin > v_cursor then
        v_cursor := v_ocupado.fin;
      end if;
    end loop;

    if v_cursor < v_fin_jornada
       and (v_fin_jornada - v_cursor) >= (v_duracion_efectiva || ' minutes')::interval
    then
      barbero_id := v_barbero.id;
      hora_inicio := v_cursor;
      hora_fin := v_fin_jornada;
      return next;
    end if;
  end loop;
end;
$$;


ALTER FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid, p_promocion_id uuid) OWNER TO postgres;

--
-- Name: resenas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resenas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    cita_id uuid NOT NULL,
    cliente_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    calificacion integer NOT NULL,
    comentario text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resenas_calificacion_check CHECK (((calificacion >= 1) AND (calificacion <= 5)))
);


ALTER TABLE public.resenas OWNER TO postgres;

--
-- Name: calificar_cita(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) RETURNS public.resenas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
  v_resena resenas;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null or v_cita.cliente_id is distinct from auth.uid() then
    raise exception 'Cita no encontrada.';
  end if;

  if v_cita.estado != 'completada' then
    raise exception 'Todavía no se puede calificar esta cita.';
  end if;

  if p_calificacion < 1 or p_calificacion > 5 then
    raise exception 'La calificación debe ser entre 1 y 5.';
  end if;

  if exists (select 1 from public.resenas where cita_id = p_cita_id) then
    raise exception 'Ya calificaste esta cita.';
  end if;

  insert into public.resenas (barberia_id, cita_id, cliente_id, barbero_id, calificacion, comentario)
  values (v_cita.barberia_id, p_cita_id, auth.uid(), v_cita.barbero_id, p_calificacion, p_comentario)
  returning * into v_resena;

  return v_resena;
end;
$$;


ALTER FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) OWNER TO postgres;

--
-- Name: citas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.citas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    cliente_id uuid,
    servicio_id uuid NOT NULL,
    fecha_hora timestamp with time zone NOT NULL,
    duracion_min integer NOT NULL,
    estado public.estado_cita DEFAULT 'pendiente'::public.estado_cita NOT NULL,
    precio_cobrado numeric(10,2),
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    cliente_walkin_id uuid,
    promocion_id uuid,
    descuento_aplicado numeric(10,2) DEFAULT 0 NOT NULL,
    completado_por uuid,
    cancelado_por uuid,
    CONSTRAINT citas_descuento_aplicado_check CHECK ((descuento_aplicado >= (0)::numeric)),
    CONSTRAINT citas_duracion_min_check CHECK ((duracion_min > 0)),
    CONSTRAINT citas_un_solo_tipo_cliente CHECK ((((cliente_id IS NOT NULL) AND (cliente_walkin_id IS NULL)) OR ((cliente_id IS NULL) AND (cliente_walkin_id IS NOT NULL))))
);


ALTER TABLE public.citas OWNER TO postgres;

--
-- Name: COLUMN citas.completado_por; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.citas.completado_por IS 'Quien (perfiles.id) ejecuto la accion que dejo esta cita en estado completada. Null si aun no se completo.';


--
-- Name: COLUMN citas.cancelado_por; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.citas.cancelado_por IS 'Quien (perfiles.id) ejecuto la accion que saco esta cita del flujo normal sin completarse: sirve tanto para estado cancelada como no_asistio. Null si fue un cron automatico (cancelar_citas_pago_vencido/marcar_no_asistio_vencidas) o si la cita aun no llego a ninguno de los dos estados.';


--
-- Name: cancelar_cita_cliente(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) RETURNS public.citas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
  v_minutos integer;
  v_mensaje text;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null or v_cita.cliente_id is distinct from auth.uid() then
    raise exception 'Cita no encontrada.';
  end if;

  if v_cita.estado = 'confirmada' then
    raise exception 'Ya hiciste check-in para esta cita, para cancelarla hablá con el local.';
  elsif v_cita.estado != 'pendiente' then
    raise exception 'Esta cita ya no se puede cancelar.';
  end if;

  v_minutos := coalesce(
    (
      select (cb.valor ->> 'minutos')::int
      from public.configuraciones_barberia cb
      where cb.barberia_id = v_cita.barberia_id
        and cb.clave = 'minutos_minimos_cancelacion_cliente'
    ),
    120
  );

  if v_cita.fecha_hora - now() < (v_minutos || ' minutes')::interval then
    v_mensaje := 'Faltan menos de ' || v_minutos || ' minutos para tu cita, contactá al local para cancelarla.';
    raise exception '%', v_mensaje;
  end if;

  update public.citas
  set estado = 'cancelada', cancelado_por = auth.uid()
  where id = p_cita_id and cliente_id = auth.uid() and estado = 'pendiente'
  returning * into v_cita;

  if not found then
    raise exception 'Esta cita ya no se puede cancelar.';
  end if;

  return v_cita;
end;
$$;


ALTER FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) OWNER TO postgres;

--
-- Name: cancelar_citas_pago_vencido(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancelar_citas_pago_vencido() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  update public.citas c
  set estado = 'cancelada'
  where c.estado = 'pendiente'
    and exists (
      select 1 from public.configuraciones_barberia cb
      where cb.barberia_id = c.barberia_id
        and cb.clave = 'modo_pago'
        and cb.valor ->> 'modo' in ('obligatorio', 'sena')
    )
    and not exists (
      select 1 from public.pagos p
      where p.cita_id = c.id and p.estado = 'confirmado'
    )
    and now() - greatest(
      c.creado_en,
      coalesce(
        (select p.fecha from public.pagos p where p.cita_id = c.id),
        c.creado_en
      )
    ) > (
      coalesce(
        (
          select (cb.valor ->> 'minutos')::int
          from public.configuraciones_barberia cb
          where cb.barberia_id = c.barberia_id and cb.clave = 'minutos_gracia_pago'
        ),
        30
      ) || ' minutes'
    )::interval;
end;
$$;


ALTER FUNCTION public.cancelar_citas_pago_vencido() OWNER TO postgres;

--
-- Name: turnos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.turnos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    numero integer NOT NULL,
    cliente_id uuid,
    cliente_walkin_id uuid,
    servicio_id uuid NOT NULL,
    barbero_id uuid,
    estado public.estado_turno DEFAULT 'esperando'::public.estado_turno NOT NULL,
    cita_id uuid,
    hora_llegada timestamp with time zone DEFAULT now() NOT NULL,
    hora_atencion timestamp with time zone,
    hora_completado timestamp with time zone,
    monto_precobrado numeric(10,2),
    metodo_precobrado public.metodo_pago,
    CONSTRAINT turnos_check CHECK ((((cliente_id IS NOT NULL) AND (cliente_walkin_id IS NULL)) OR ((cliente_id IS NULL) AND (cliente_walkin_id IS NOT NULL))))
);


ALTER TABLE public.turnos OWNER TO postgres;

--
-- Name: cancelar_turno(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancelar_turno(p_turno_id uuid) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_turno turnos;
begin
  select * into v_turno from public.turnos where id = p_turno_id;
  if v_turno is null then
    raise exception 'Turno no encontrado.';
  end if;

  perform validar_permiso_turno(v_turno.sucursal_id);

  if v_turno.estado not in ('esperando', 'en_atencion') then
    raise exception 'Este turno ya no se puede cancelar.';
  end if;

  update public.turnos set estado = 'cancelado' where id = p_turno_id
  returning * into v_turno;

  if v_turno.cita_id is not null then
    update public.citas set estado = 'cancelada', cancelado_por = auth.uid()
    where id = v_turno.cita_id and estado = 'confirmada';
  end if;

  return v_turno;
end;
$$;


ALTER FUNCTION public.cancelar_turno(p_turno_id uuid) OWNER TO postgres;

--
-- Name: programas_ranking_barberos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.programas_ranking_barberos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    titulo text NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date NOT NULL,
    peso_citas integer DEFAULT 0 NOT NULL,
    peso_ingresos integer DEFAULT 0 NOT NULL,
    peso_clientes integer DEFAULT 0 NOT NULL,
    peso_puntualidad integer DEFAULT 0 NOT NULL,
    tipo_premio text NOT NULL,
    descripcion_premio text NOT NULL,
    estado text DEFAULT 'activo'::text NOT NULL,
    barbero_ganador_id uuid,
    premio_entregado boolean DEFAULT false NOT NULL,
    cerrado_en timestamp with time zone,
    cerrado_por uuid,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    peso_calificacion integer DEFAULT 0 NOT NULL,
    CONSTRAINT fechas_validas CHECK ((fecha_fin >= fecha_inicio)),
    CONSTRAINT pesos_suman_100 CHECK ((((((peso_citas + peso_ingresos) + peso_clientes) + peso_puntualidad) + peso_calificacion) = 100)),
    CONSTRAINT programas_ranking_barberos_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'cerrado'::text]))),
    CONSTRAINT programas_ranking_barberos_peso_calificacion_check CHECK (((peso_calificacion >= 0) AND (peso_calificacion <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_citas_check CHECK (((peso_citas >= 0) AND (peso_citas <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_clientes_check CHECK (((peso_clientes >= 0) AND (peso_clientes <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_ingresos_check CHECK (((peso_ingresos >= 0) AND (peso_ingresos <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_puntualidad_check CHECK (((peso_puntualidad >= 0) AND (peso_puntualidad <= 100))),
    CONSTRAINT programas_ranking_barberos_tipo_premio_check CHECK ((tipo_premio = ANY (ARRAY['dinero'::text, 'insumo'::text, 'sorpresa'::text, 'otro'::text])))
);


ALTER TABLE public.programas_ranking_barberos OWNER TO postgres;

--
-- Name: cerrar_programa_ranking(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) RETURNS public.programas_ranking_barberos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_programa programas_ranking_barberos;
  v_ganador uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'No tienes permiso para cerrar este programa.';
  end if;

  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa is null or v_programa.barberia_id != obtener_barberia_id_actual() then
    raise exception 'Programa no encontrado.';
  end if;
  if v_programa.fecha_fin > current_date then
    raise exception 'Todavía no llegó la fecha fin del programa.';
  end if;

  perform pg_advisory_xact_lock(hashtext('cerrar_ranking:' || p_programa_id::text));

  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa.estado != 'activo' then
    raise exception 'Este programa ya está cerrado.';
  end if;

  insert into public.insignias_ranking_barberos (programa_id, barbero_id, puesto)
  select p_programa_id, r.barbero_id, r.puesto
  from public.obtener_ranking_barberos(p_programa_id) r
  where r.puesto <= 3
  on conflict (programa_id, barbero_id) do nothing;

  select r.barbero_id into v_ganador
  from public.obtener_ranking_barberos(p_programa_id) r
  where r.puesto = 1
  limit 1;

  if v_ganador is null then
    raise exception 'No hay barberos con actividad en este período para premiar.';
  end if;

  update public.programas_ranking_barberos
  set estado = 'cerrado',
      barbero_ganador_id = v_ganador,
      cerrado_en = now(),
      cerrado_por = auth.uid()
  where id = p_programa_id
  returning * into v_programa;

  return v_programa;
end;
$$;


ALTER FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) OWNER TO postgres;

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

--
-- Name: confirmar_llegada_cita(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita record;
  v_barberia_id uuid;
  v_numero integer;
  v_turno turnos;
begin
  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null then
    raise exception 'Cita no encontrada.';
  end if;

  v_barberia_id := validar_permiso_turno(v_cita.sucursal_id);

  perform pg_advisory_xact_lock(hashtext(v_cita.sucursal_id::text || current_date::text));

  update public.citas set estado = 'confirmada'
  where id = p_cita_id and estado = 'pendiente'
  returning * into v_cita;

  if not found then
    raise exception 'Esta cita no está pendiente de check-in.';
  end if;

  select coalesce(max(numero), 0) + 1 into v_numero
  from public.turnos
  where sucursal_id = v_cita.sucursal_id and hora_llegada::date = current_date;

  insert into public.turnos (
    barberia_id, sucursal_id, numero, cliente_id, cliente_walkin_id, servicio_id,
    barbero_id, cita_id
  ) values (
    v_barberia_id, v_cita.sucursal_id, v_numero, v_cita.cliente_id, v_cita.cliente_walkin_id,
    v_cita.servicio_id, v_cita.barbero_id, v_cita.id
  ) returning * into v_turno;

  return v_turno;
end;
$$;


ALTER FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) OWNER TO postgres;

--
-- Name: pagos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    cita_id uuid NOT NULL,
    monto numeric(10,2) NOT NULL,
    metodo public.metodo_pago DEFAULT 'qr_manual'::public.metodo_pago NOT NULL,
    estado public.estado_pago DEFAULT 'pendiente'::public.estado_pago NOT NULL,
    url_comprobante text,
    verificado_por uuid,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pagos_monto_check CHECK ((monto >= (0)::numeric))
);


ALTER TABLE public.pagos OWNER TO postgres;

--
-- Name: confirmar_pago(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.confirmar_pago(p_pago_id uuid) RETURNS public.pagos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_pago pagos;
begin
  if not (
    es_superadmin()
    or (
      es_admin_o_superior()
      and exists (
        select 1 from public.pagos p
        where p.id = p_pago_id and p.barberia_id = obtener_barberia_id_actual()
      )
    )
  ) then
    raise exception 'No tienes permiso para verificar este pago.';
  end if;

  update public.pagos
  set estado = 'confirmado', verificado_por = auth.uid()
  where id = p_pago_id and estado = 'por_verificar'
  returning * into v_pago;

  if not found then
    raise exception 'Este pago no está pendiente de verificación.';
  end if;

  return v_pago;
end;
$$;


ALTER FUNCTION public.confirmar_pago(p_pago_id uuid) OWNER TO postgres;

--
-- Name: crear_turno(uuid, uuid, uuid, uuid, numeric, public.metodo_pago); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric DEFAULT NULL::numeric, p_metodo_precobrado public.metodo_pago DEFAULT NULL::public.metodo_pago) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_numero integer;
  v_turno turnos;
begin
  v_barberia_id := validar_permiso_turno(p_sucursal_id);

  perform pg_advisory_xact_lock(hashtext(p_sucursal_id::text || current_date::text));

  select coalesce(max(numero), 0) + 1 into v_numero
  from public.turnos
  where sucursal_id = p_sucursal_id and hora_llegada::date = current_date;

  insert into public.turnos (
    barberia_id, sucursal_id, numero, cliente_id, cliente_walkin_id, servicio_id,
    monto_precobrado, metodo_precobrado
  ) values (
    v_barberia_id, p_sucursal_id, v_numero, p_cliente_id, p_cliente_walkin_id, p_servicio_id,
    p_monto_precobrado, p_metodo_precobrado
  ) returning * into v_turno;

  return v_turno;
end;
$$;


ALTER FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) OWNER TO postgres;

--
-- Name: crear_turno_walkin(uuid, uuid, text, text, numeric, public.metodo_pago); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric DEFAULT NULL::numeric, p_metodo_precobrado public.metodo_pago DEFAULT NULL::public.metodo_pago) RETURNS public.turnos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_cliente_walkin_id uuid;
begin
  v_barberia_id := validar_permiso_turno(p_sucursal_id);

  insert into public.clientes_walkin (barberia_id, nombre, telefono)
  values (v_barberia_id, p_nombre, p_telefono)
  on conflict (barberia_id, telefono)
  do update set nombre = excluded.nombre
  returning id into v_cliente_walkin_id;

  return crear_turno(
    p_sucursal_id, p_servicio_id, null, v_cliente_walkin_id,
    p_monto_precobrado, p_metodo_precobrado
  );
end;
$$;


ALTER FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) OWNER TO postgres;

--
-- Name: es_admin_o_superior(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_admin_o_superior() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_rol_actual() in ('admin', 'superadmin');
$$;


ALTER FUNCTION public.es_admin_o_superior() OWNER TO postgres;

--
-- Name: es_admin_o_superior_o_secretaria(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_admin_o_superior_o_secretaria() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_rol_actual() in ('admin', 'superadmin', 'secretaria');
$$;


ALTER FUNCTION public.es_admin_o_superior_o_secretaria() OWNER TO postgres;

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

--
-- Name: es_cliente_o_superior(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_barberia_id_actual() = p_barberia_id or es_superadmin();
$$;


ALTER FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) OWNER TO postgres;

--
-- Name: es_superadmin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.es_superadmin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select obtener_rol_actual() = 'superadmin';
$$;


ALTER FUNCTION public.es_superadmin() OWNER TO postgres;

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

--
-- Name: fecha_utc_inmutable(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) RETURNS date
    LANGUAGE sql IMMUTABLE
    AS $$
  select (marca at time zone 'utc')::date
$$;


ALTER FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) OWNER TO postgres;

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

--
-- Name: invitar_secretaria_por_email(text, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.invitar_secretaria_por_email(email_secretaria text, id_sucursal uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_perfil_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede invitar secretarias.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  select id into v_perfil_id
  from public.perfiles
  where email = email_secretaria;

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
  set rol = 'secretaria',
      barberia_id = v_barberia_id,
      sucursal_id = id_sucursal
  where id = v_perfil_id;
end;
$$;


ALTER FUNCTION public.invitar_secretaria_por_email(email_secretaria text, id_sucursal uuid) OWNER TO postgres;

--
-- Name: llamar_turno(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_turno record;
  v_servicio record;
  v_fin_estimado timestamptz;
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
    raise exception 'No tienes permiso para llamar este turno.';
  end if;

  if v_turno.estado != 'esperando' then
    raise exception 'El turno debe estar esperando para poder llamarlo.';
  end if;

  select * into v_servicio from public.servicios where id = v_turno.servicio_id;
  v_fin_estimado := now() + (v_servicio.duracion_min || ' minutes')::interval;

  if exists (
    select 1 from public.citas c
    where c.barbero_id = p_barbero_id
      and c.estado in ('pendiente', 'confirmada')
      and (v_turno.cita_id is null or c.id != v_turno.cita_id)
      and now() < c.fecha_hora + (c.duracion_min || ' minutes')::interval
      and v_fin_estimado > c.fecha_hora
  ) then
    raise exception 'Ese barbero tiene una cita reservada pronto, no está disponible.';
  end if;

  if exists (
    select 1 from public.turnos t2
    where t2.barbero_id = p_barbero_id
      and t2.estado = 'en_atencion'
  ) then
    raise exception 'Ese barbero ya está atendiendo otro turno, no está disponible.';
  end if;

  update public.turnos
  set estado = 'en_atencion', barbero_id = p_barbero_id, hora_atencion = now()
  where id = p_turno_id and estado = 'esperando';

  if not found then
    raise exception 'El turno ya no está esperando (lo modificó otra operación).';
  end if;
end;
$$;


ALTER FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) OWNER TO postgres;

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

--
-- Name: marcar_cita_no_asistio(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) RETURNS public.citas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
begin
  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null then
    raise exception 'Cita no encontrada.';
  end if;

  perform validar_permiso_turno(v_cita.sucursal_id);

  if v_cita.estado != 'pendiente' then
    raise exception 'Esta cita ya no está pendiente.';
  end if;

  if v_cita.fecha_hora > now() then
    raise exception 'Todavía no es la hora de esta cita.';
  end if;

  update public.citas set estado = 'no_asistio', cancelado_por = auth.uid() where id = p_cita_id
  returning * into v_cita;

  return v_cita;
end;
$$;


ALTER FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) OWNER TO postgres;

--
-- Name: marcar_no_asistio_vencidas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.marcar_no_asistio_vencidas() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  update public.citas c
  set estado = 'no_asistio'
  where c.estado = 'pendiente'
    and now() - c.fecha_hora > (
      coalesce(
        (
          select (cb.valor ->> 'minutos')::int
          from public.configuraciones_barberia cb
          where cb.barberia_id = c.barberia_id
            and cb.clave = 'minutos_tolerancia_no_asistio'
        ),
        15
      ) || ' minutes'
    )::interval;
end;
$$;


ALTER FUNCTION public.marcar_no_asistio_vencidas() OWNER TO postgres;

--
-- Name: marcar_premio_entregado(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.marcar_premio_entregado(p_programa_id uuid) RETURNS public.programas_ranking_barberos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_programa programas_ranking_barberos;
begin
  if not es_admin_o_superior() then
    raise exception 'No tienes permiso para esta acción.';
  end if;

  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa is null or v_programa.barberia_id != obtener_barberia_id_actual() then
    raise exception 'Programa no encontrado.';
  end if;
  if v_programa.estado != 'cerrado' then
    raise exception 'El programa todavía no está cerrado.';
  end if;

  update public.programas_ranking_barberos
  set premio_entregado = true
  where id = p_programa_id
  returning * into v_programa;

  return v_programa;
end;
$$;


ALTER FUNCTION public.marcar_premio_entregado(p_programa_id uuid) OWNER TO postgres;

--
-- Name: obtener_accesos_rapidos_top(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_accesos_rapidos_top(p_limite integer DEFAULT 4) RETURNS TABLE(ruta text, usos bigint)
    LANGUAGE sql STABLE
    AS $$
  select a.ruta, count(*) as usos
  from accesos_admin_uso a
  where a.perfil_id = auth.uid()
    and a.creado_en >= now() - interval '30 days'
  group by a.ruta
  order by usos desc, a.ruta asc
  limit p_limite;
$$;


ALTER FUNCTION public.obtener_accesos_rapidos_top(p_limite integer) OWNER TO postgres;

--
-- Name: obtener_actividad_por_usuario(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(usuario_id uuid, usuario_nombre text, rol text, citas_completadas bigint, monto_total_cobrado numeric, citas_canceladas bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar este reporte.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  with completadas as (
    select
      c.completado_por as usuario_id,
      count(*) as citas_completadas,
      coalesce(sum(c.precio_cobrado), 0) as monto_total_cobrado
    from public.citas c
    where c.barberia_id = v_barberia_id
      and c.completado_por is not null
      and c.estado = 'completada'
      and c.fecha_hora >= p_fecha_inicio
      and c.fecha_hora <= p_fecha_fin
    group by c.completado_por
  ),
  canceladas as (
    select
      c.cancelado_por as usuario_id,
      count(*) as citas_canceladas
    from public.citas c
    where c.barberia_id = v_barberia_id
      and c.cancelado_por is not null
      and c.estado in ('cancelada', 'no_asistio')
      and c.fecha_hora >= p_fecha_inicio
      and c.fecha_hora <= p_fecha_fin
    group by c.cancelado_por
  )
  select
    coalesce(comp.usuario_id, canc.usuario_id) as usuario_id,
    coalesce(p.nombre, 'Usuario') as usuario_nombre,
    p.rol::text as rol,
    coalesce(comp.citas_completadas, 0) as citas_completadas,
    coalesce(comp.monto_total_cobrado, 0) as monto_total_cobrado,
    coalesce(canc.citas_canceladas, 0) as citas_canceladas
  from completadas comp
  full outer join canceladas canc on canc.usuario_id = comp.usuario_id
  left join public.perfiles p on p.id = coalesce(comp.usuario_id, canc.usuario_id)
  order by citas_completadas desc;
end;
$$;


ALTER FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_barberia_id_actual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_barberia_id_actual() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select barberia_id from public.perfiles where id = auth.uid();
$$;


ALTER FUNCTION public.obtener_barberia_id_actual() OWNER TO postgres;

--
-- Name: obtener_barberia_unica_reportes_powerbi(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_barberia_unica_reportes_powerbi() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select id from public.barberias order by creado_en asc limit 1;
$$;


ALTER FUNCTION public.obtener_barberia_unica_reportes_powerbi() OWNER TO postgres;

--
-- Name: FUNCTION obtener_barberia_unica_reportes_powerbi(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.obtener_barberia_unica_reportes_powerbi() IS 'Devuelve el id de la única barbería real del sistema (Fase 1). Usado solo por las vistas de reportes de Power BI (vista_reportes_*). Ver comentario "LIMITACIÓN TEMPORAL" en 0048_rol_lectura_powerbi.sql: deja de alcanzar en cuanto haya una 2da barbería real (Fase 4).';


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

--
-- Name: obtener_citas_atendidas_dia(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) RETURNS TABLE(cita_id uuid, hora timestamp with time zone, cliente_nombre text, servicio_nombre text, barbero_nombre text, monto numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_dia_inicio timestamptz;
  v_dia_fin timestamptz;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar la actividad diaria.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  v_dia_inicio := p_fecha::timestamp at time zone 'America/La_Paz';
  v_dia_fin := v_dia_inicio + interval '1 day';

  return query
  select
    c.id as cita_id,
    c.fecha_hora as hora,
    coalesce(p.nombre, cw.nombre, 'Cliente') as cliente_nombre,
    case
      when c.promocion_id is not null
        and jsonb_array_length(coalesce(promo.nombres_servicios, '[]'::jsonb)) > 1
      then array_to_string(
        array(select jsonb_array_elements_text(promo.nombres_servicios)),
        ' + '
      )
      else sv.nombre
    end as servicio_nombre,
    coalesce(bp.nombre, 'Barbero') as barbero_nombre,
    c.precio_cobrado as monto
  from public.citas c
  left join public.perfiles p on p.id = c.cliente_id
  left join public.clientes_walkin cw on cw.id = c.cliente_walkin_id
  left join public.servicios sv on sv.id = c.servicio_id
  left join public.promociones promo on promo.id = c.promocion_id
  left join public.barberos b on b.id = c.barbero_id
  left join public.perfiles bp on bp.id = b.perfil_id
  where c.barberia_id = v_barberia_id
    and c.estado = 'completada'
    and c.fecha_hora >= v_dia_inicio
    and c.fecha_hora < v_dia_fin
  order by c.fecha_hora asc;
end;
$$;


ALTER FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) OWNER TO postgres;

--
-- Name: obtener_citas_sin_pago_completo(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(cita_id uuid, fecha_hora timestamp with time zone, cliente_nombre text, barbero_nombre text, precio_cobrado numeric, monto_pagado numeric, diferencia numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar este reporte.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    c.id as cita_id,
    c.fecha_hora,
    coalesce(p_cliente.nombre, cw.nombre, 'Cliente') as cliente_nombre,
    coalesce(p_barbero.nombre, 'Barbero') as barbero_nombre,
    coalesce(c.precio_cobrado, 0) as precio_cobrado,
    coalesce(pc.monto_pagado, 0) as monto_pagado,
    (coalesce(c.precio_cobrado, 0) - coalesce(pc.monto_pagado, 0)) as diferencia
  from public.citas c
  left join public.perfiles p_cliente on p_cliente.id = c.cliente_id
  left join public.clientes_walkin cw on cw.id = c.cliente_walkin_id
  left join public.barberos b on b.id = c.barbero_id
  left join public.perfiles p_barbero on p_barbero.id = b.perfil_id
  left join lateral (
    select coalesce(sum(pg.monto), 0) as monto_pagado
    from public.pagos pg
    where pg.cita_id = c.id and pg.estado = 'confirmado'
  ) pc on true
  where c.barberia_id = v_barberia_id
    and c.estado = 'completada'
    and c.fecha_hora >= p_fecha_inicio
    and c.fecha_hora <= p_fecha_fin
    and (coalesce(c.precio_cobrado, 0) - coalesce(pc.monto_pagado, 0)) > 0
  order by diferencia desc;
end;
$$;


ALTER FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_clientes_nuevos_dia(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) RETURNS TABLE(cliente_id uuid, nombre text, telefono text, hora_registro timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_dia_inicio timestamptz;
  v_dia_fin timestamptz;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar la actividad diaria.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  v_dia_inicio := p_fecha::timestamp at time zone 'America/La_Paz';
  v_dia_fin := v_dia_inicio + interval '1 day';

  return query
  select
    p.id as cliente_id,
    p.nombre,
    p.telefono,
    p.creado_en as hora_registro
  from public.perfiles p
  where p.barberia_id = v_barberia_id
    and p.rol = 'cliente'
    and p.creado_en >= v_dia_inicio
    and p.creado_en < v_dia_fin
  order by p.creado_en asc;
end;
$$;


ALTER FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) OWNER TO postgres;

--
-- Name: obtener_grilla_horarios(uuid, uuid, date, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) RETURNS TABLE(hora_inicio timestamp with time zone, libre boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar horarios de esta sucursal.';
  end if;

  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  if not exists (
    select 1 from public.barberos b
    where b.id = p_barbero_id
      and b.sucursal_id = p_sucursal_id
      and b.activo = true
  ) then
    raise exception 'Barbero no encontrado.';
  end if;

  return query
  select
    slot.hora_inicio,
    not exists (
      select 1
      from public.citas c
      where c.barbero_id = p_barbero_id
        and c.estado in ('pendiente', 'confirmada', 'completada')
        and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
        and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
    ) as libre
  from public.horarios_barbero h
  cross join lateral (
    select
      ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
        + (n * v_duracion_min || ' minutes')::interval as hora_inicio
    from generate_series(
      0,
      (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
    ) as n
  ) as slot
  where h.barbero_id = p_barbero_id
    and h.dia_semana = extract(dow from p_fecha)::smallint
    and slot.hora_inicio >= now()
  order by slot.hora_inicio;
end;
$$;


ALTER FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) OWNER TO postgres;

--
-- Name: obtener_grilla_horarios(uuid, uuid, date, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid DEFAULT NULL::uuid) RETURNS TABLE(hora_inicio timestamp with time zone, libre boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_promo record;
  v_duracion_combo integer;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar horarios de esta sucursal.';
  end if;

  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  -- Mismo override de duracion para combos que obtener_horarios_disponibles
  -- (ver comentario de cabecera de esta migracion).
  if p_promocion_id is not null then
    select * into v_promo
    from public.promociones
    where id = p_promocion_id
      and barberia_id = v_barberia_id;

    if v_promo is not null
       and v_promo.servicios_ids is not null
       and jsonb_array_length(v_promo.servicios_ids) > 1
    then
      select coalesce(sum(sv.duracion_min), 0) into v_duracion_combo
      from public.servicios sv
      where sv.id in (
        select jsonb_array_elements_text(v_promo.servicios_ids)::uuid
      )
      and sv.barberia_id = v_barberia_id;

      if v_duracion_combo > 0 then
        v_duracion_min := v_duracion_combo;
      end if;
    end if;
  end if;

  if not exists (
    select 1 from public.barberos b
    where b.id = p_barbero_id
      and b.sucursal_id = p_sucursal_id
      and b.activo = true
  ) then
    raise exception 'Barbero no encontrado.';
  end if;

  return query
  select
    slot.hora_inicio,
    not exists (
      select 1
      from public.citas c
      where c.barbero_id = p_barbero_id
        and c.estado in ('pendiente', 'confirmada', 'completada')
        and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
        and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
    ) as libre
  from public.horarios_barbero h
  cross join lateral (
    select
      ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
        + (n * v_duracion_min || ' minutes')::interval as hora_inicio
    from generate_series(
      0,
      (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
    ) as n
  ) as slot
  where h.barbero_id = p_barbero_id
    and h.dia_semana = extract(dow from p_fecha)::smallint
    and slot.hora_inicio >= now()
  order by slot.hora_inicio;
end;
$$;


ALTER FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) OWNER TO postgres;

--
-- Name: obtener_horarios_disponibles(uuid, uuid, date, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid DEFAULT NULL::uuid) RETURNS TABLE(barbero_id uuid, hora_inicio timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_es_hoy boolean;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar horarios de esta sucursal.';
  end if;

  -- sv.barberia_id = v_barberia_id: sin esto, un servicio_id de OTRA
  -- barbería pasaría el chequeo (duracion_min existe igual) y filtraria
  -- horarios con una duracion ajena al tenant.
  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  v_es_hoy := p_fecha = (now() at time zone 'America/La_Paz')::date;

  if v_es_hoy then
    return query
    select b.id as barbero_id, slot.hora_inicio
    from public.barberos b
    join public.horarios_barbero h
      on h.barbero_id = b.id
     and h.dia_semana = extract(dow from p_fecha)::smallint
    cross join lateral (
      -- generate_series no funciona directo sobre "time": se genera un
      -- contador entero n (uno por slot) y se le suma su offset en minutos
      -- a hora_inicio. Cuando el rango no da para ningun slot completo
      -- (numero <= 0), generate_series(0, -1) devuelve cero filas.
      select
        ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
          + (n * v_duracion_min || ' minutes')::interval as hora_inicio
      from generate_series(
        0,
        (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
      ) as n
    ) as slot
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
      -- Excluye slots que se solapan con una cita ya tomada de ese barbero
      -- (comparacion de intervalos semiabiertos [inicio, fin)). Incluye
      -- 'completada' ademas de 'pendiente'/'confirmada' para quedar de
      -- acuerdo con idx_citas_barbero_fecha_hora_activa (0024): una cita ya
      -- atendida en ese horario+barbero sigue siendo un dato real, no un
      -- hueco libre para re-reservar.
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    union
    -- Huecos reales de HOY (ver calcular_huecos_libres_hoy mas arriba). El
    -- UNION (no union all) descarta el caso borde en que un hueco arranque
    -- justo en un slot de la grilla que ya estaba libre. El if externo ya
    -- garantiza que solo se llega aca cuando p_fecha es hoy, por eso no
    -- hace falta repetir el filtro de fecha sobre calcular_huecos_libres_hoy.
    select huecos.barbero_id, huecos.hora_inicio
    from public.calcular_huecos_libres_hoy(p_sucursal_id, v_duracion_min, p_barbero_id) as huecos
    order by hora_inicio, barbero_id;
  else
    -- Fecha distinta de hoy: solo la grilla fija, identica a la de arriba,
    -- sin invocar calcular_huecos_libres_hoy en absoluto.
    return query
    select b.id as barbero_id, slot.hora_inicio
    from public.barberos b
    join public.horarios_barbero h
      on h.barbero_id = b.id
     and h.dia_semana = extract(dow from p_fecha)::smallint
    cross join lateral (
      select
        ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
          + (n * v_duracion_min || ' minutes')::interval as hora_inicio
      from generate_series(
        0,
        (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
      ) as n
    ) as slot
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    order by hora_inicio, barbero_id;
  end if;
end;
$$;


ALTER FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) OWNER TO postgres;

--
-- Name: obtener_horarios_disponibles(uuid, uuid, date, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid DEFAULT NULL::uuid, p_promocion_id uuid DEFAULT NULL::uuid) RETURNS TABLE(barbero_id uuid, hora_inicio timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_es_hoy boolean;
  v_promo record;
  v_duracion_combo integer;
begin
  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para consultar horarios de esta sucursal.';
  end if;

  -- sv.barberia_id = v_barberia_id: sin esto, un servicio_id de OTRA
  -- barbería pasaría el chequeo (duracion_min existe igual) y filtraria
  -- horarios con una duracion ajena al tenant.
  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  -- Si la reserva es por una promocion combo (2+ servicios), la duracion
  -- del bloque debe ser la suma de TODOS los servicios del combo, no solo
  -- la de p_servicio_id (que actua como "ancla" del combo) -- mismo
  -- criterio que reservar_cita (0040) usa para el chequeo real de solape
  -- al confirmar. Sin este ajuste, un cliente podia ver como "libre" un
  -- horario que en realidad no alcanza para el combo completo.
  if p_promocion_id is not null then
    select * into v_promo
    from public.promociones
    where id = p_promocion_id
      and barberia_id = v_barberia_id;

    if v_promo is not null
       and v_promo.servicios_ids is not null
       and jsonb_array_length(v_promo.servicios_ids) > 1
    then
      select coalesce(sum(sv.duracion_min), 0) into v_duracion_combo
      from public.servicios sv
      where sv.id in (
        select jsonb_array_elements_text(v_promo.servicios_ids)::uuid
      )
      and sv.barberia_id = v_barberia_id;

      if v_duracion_combo > 0 then
        v_duracion_min := v_duracion_combo;
      end if;
    end if;
  end if;

  v_es_hoy := p_fecha = (now() at time zone 'America/La_Paz')::date;

  if v_es_hoy then
    return query
    select b.id as barbero_id, slot.hora_inicio
    from public.barberos b
    join public.horarios_barbero h
      on h.barbero_id = b.id
     and h.dia_semana = extract(dow from p_fecha)::smallint
    cross join lateral (
      -- generate_series no funciona directo sobre "time": se genera un
      -- contador entero n (uno por slot) y se le suma su offset en minutos
      -- a hora_inicio. Cuando el rango no da para ningun slot completo
      -- (numero <= 0), generate_series(0, -1) devuelve cero filas.
      select
        ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
          + (n * v_duracion_min || ' minutes')::interval as hora_inicio
      from generate_series(
        0,
        (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
      ) as n
    ) as slot
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
      -- Excluye slots que se solapan con una cita ya tomada de ese barbero
      -- (comparacion de intervalos semiabiertos [inicio, fin)). Incluye
      -- 'completada' ademas de 'pendiente'/'confirmada' para quedar de
      -- acuerdo con idx_citas_barbero_fecha_hora_activa (0024): una cita ya
      -- atendida en ese horario+barbero sigue siendo un dato real, no un
      -- hueco libre para re-reservar.
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    union
    -- Huecos reales de HOY (ver calcular_huecos_libres_hoy mas arriba). El
    -- UNION (no union all) descarta el caso borde en que un hueco arranque
    -- justo en un slot de la grilla que ya estaba libre. El if externo ya
    -- garantiza que solo se llega aca cuando p_fecha es hoy, por eso no
    -- hace falta repetir el filtro de fecha sobre calcular_huecos_libres_hoy.
    select huecos.barbero_id, huecos.hora_inicio
    from public.calcular_huecos_libres_hoy(p_sucursal_id, v_duracion_min, p_barbero_id, p_promocion_id) as huecos
    order by hora_inicio, barbero_id;
  else
    -- Fecha distinta de hoy: solo la grilla fija, identica a la de arriba,
    -- sin invocar calcular_huecos_libres_hoy en absoluto.
    return query
    select b.id as barbero_id, slot.hora_inicio
    from public.barberos b
    join public.horarios_barbero h
      on h.barbero_id = b.id
     and h.dia_semana = extract(dow from p_fecha)::smallint
    cross join lateral (
      select
        ((p_fecha + h.hora_inicio) at time zone 'America/La_Paz')
          + (n * v_duracion_min || ' minutes')::interval as hora_inicio
      from generate_series(
        0,
        (extract(epoch from (h.hora_fin - h.hora_inicio))::integer / 60 / v_duracion_min) - 1
      ) as n
    ) as slot
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and (p_barbero_id is null or b.id = p_barbero_id)
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and slot.hora_inicio < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and slot.hora_inicio + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    order by hora_inicio, barbero_id;
  end if;
end;
$$;


ALTER FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) OWNER TO postgres;

--
-- Name: obtener_ingresos_por_metodo_pago(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(metodo text, monto_total numeric, cantidad_pagos bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar este reporte.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    pg.metodo::text as metodo,
    coalesce(sum(pg.monto), 0) as monto_total,
    count(*) as cantidad_pagos
  from public.pagos pg
  where pg.barberia_id = v_barberia_id
    and pg.estado = 'confirmado'
    and pg.fecha >= p_fecha_inicio
    and pg.fecha <= p_fecha_fin
  group by pg.metodo
  order by monto_total desc;
end;
$$;


ALTER FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

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

--
-- Name: obtener_progreso_fidelidad_cliente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_progreso_fidelidad_cliente() RETURNS TABLE(programa_id uuid, titulo text, progreso_actual integer, meta_citas integer, puede_reclamar boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    return;
  end if;

  return query
  with progreso as (
    select
      pf.id as p_id,
      pf.titulo as p_titulo,
      pf.meta_citas as p_meta,
      coalesce((
        select count(*)::integer
        from public.citas c
        where c.cliente_id = auth.uid()
          and c.estado = 'completada'
          and c.servicio_id in (
            select jsonb_array_elements_text(pf.servicios_ids)::uuid
          )
          and c.fecha_hora > coalesce(
            (
              select max(rf.reclamado_en)
              from public.reclamaciones_fidelidad rf
              where rf.programa_id = pf.id and rf.cliente_id = auth.uid()
            ),
            pf.creado_en
          )
      ), 0) as p_progreso
    from public.programas_fidelidad pf
    where pf.barberia_id = v_barberia_id
      and pf.activo = true
      and (pf.fecha_inicio is null or pf.fecha_inicio <= current_date)
      and (pf.fecha_fin is null or pf.fecha_fin >= current_date)
  )
  select
    p_id,
    p_titulo,
    p_progreso,
    p_meta,
    p_progreso >= p_meta
  from progreso;
end;
$$;


ALTER FUNCTION public.obtener_progreso_fidelidad_cliente() OWNER TO postgres;

--
-- Name: obtener_ranking_barberos(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) RETURNS TABLE(barbero_id uuid, nombre text, puesto integer, puntaje numeric, citas_completadas integer, puesto_citas integer, ingresos_generados numeric, puesto_ingresos integer, clientes_distintos integer, puesto_clientes integer, tasa_no_show numeric, puesto_puntualidad integer, calificacion_promedio numeric, puesto_calificacion integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_programa programas_ranking_barberos;
  v_desde timestamptz;
  v_hasta timestamptz;
begin
  select * into v_programa from public.programas_ranking_barberos where id = p_programa_id;
  if v_programa is null then
    raise exception 'Programa no encontrado.';
  end if;
  if v_programa.barberia_id != obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para ver este programa.';
  end if;

  v_desde := (v_programa.fecha_inicio::timestamp at time zone 'America/La_Paz');
  v_hasta := ((v_programa.fecha_fin + 1)::timestamp at time zone 'America/La_Paz');

  return query
  with base as (
    select
      b.id as barbero_id,
      p.nombre as nombre,
      coalesce(count(c.id) filter (where c.estado = 'completada'), 0)::integer as citas_completadas,
      coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as ingresos_generados,
      coalesce(count(distinct c.cliente_id) filter (where c.estado = 'completada'), 0)::integer as clientes_distintos,
      case
        when count(c.id) filter (where c.estado in ('completada', 'no_asistio')) = 0 then 0
        else count(c.id) filter (where c.estado = 'no_asistio')::numeric
             / count(c.id) filter (where c.estado in ('completada', 'no_asistio'))::numeric
      end as tasa_no_show,
      coalesce(avg(res.calificacion), 0) as calificacion_promedio
    from public.barberos b
    join public.perfiles p on p.id = b.perfil_id
    left join public.citas c
      on c.barbero_id = b.id
      and c.fecha_hora >= v_desde
      and c.fecha_hora < v_hasta
    left join public.resenas res
      on res.cita_id = c.id
    where b.sucursal_id = v_programa.sucursal_id
      and (
        b.activo = true
        or exists (
          select 1 from public.citas c2
          where c2.barbero_id = b.id
            and c2.fecha_hora >= v_desde
            and c2.fecha_hora < v_hasta
        )
      )
    group by b.id, p.nombre
  ),
  maximos as (
    select
      greatest(max(citas_completadas), 1) as max_citas,
      greatest(max(ingresos_generados), 1) as max_ingresos,
      greatest(max(clientes_distintos), 1) as max_clientes
    from base
  ),
  puntuado as (
    select
      base.*,
      (base.citas_completadas::numeric / maximos.max_citas * 100) as score_citas,
      (base.ingresos_generados / maximos.max_ingresos * 100) as score_ingresos,
      (base.clientes_distintos::numeric / maximos.max_clientes * 100) as score_clientes,
      ((1 - base.tasa_no_show) * 100) as score_puntualidad,
      (base.calificacion_promedio / 5 * 100) as score_calificacion
    from base, maximos
  ),
  final as (
    select
      puntuado.*,
      (v_programa.peso_citas::numeric / 100 * score_citas)
        + (v_programa.peso_ingresos::numeric / 100 * score_ingresos)
        + (v_programa.peso_clientes::numeric / 100 * score_clientes)
        + (v_programa.peso_puntualidad::numeric / 100 * score_puntualidad)
        + (v_programa.peso_calificacion::numeric / 100 * score_calificacion)
        as puntaje_final,
      rank() over (order by citas_completadas desc) as rk_citas,
      rank() over (order by ingresos_generados desc) as rk_ingresos,
      rank() over (order by clientes_distintos desc) as rk_clientes,
      rank() over (order by tasa_no_show asc) as rk_puntualidad,
      rank() over (order by calificacion_promedio desc) as rk_calificacion
    from puntuado
  )
  select
    final.barbero_id,
    final.nombre,
    rank() over (order by final.puntaje_final desc, final.ingresos_generados desc)::integer as puesto,
    round(final.puntaje_final, 2) as puntaje,
    final.citas_completadas,
    final.rk_citas::integer as puesto_citas,
    final.ingresos_generados,
    final.rk_ingresos::integer as puesto_ingresos,
    final.clientes_distintos,
    final.rk_clientes::integer as puesto_clientes,
    round(final.tasa_no_show, 4) as tasa_no_show,
    final.rk_puntualidad::integer as puesto_puntualidad,
    round(final.calificacion_promedio, 2) as calificacion_promedio,
    final.rk_calificacion::integer as puesto_calificacion
  from final
  order by puesto asc;
end;
$$;


ALTER FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) OWNER TO postgres;

--
-- Name: obtener_reporte_clientes_frecuentes(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(cliente_id uuid, cliente_nombre text, cantidad_citas bigint, monto_total numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar los reportes de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    c.cliente_id,
    coalesce(p.nombre, 'Cliente') as cliente_nombre,
    count(c.id) as cantidad_citas,
    coalesce(sum(c.precio_cobrado), 0) as monto_total
  from public.citas c
  left join public.perfiles p on p.id = c.cliente_id
  where c.barberia_id = v_barberia_id
    and c.cliente_id is not null
    and c.estado = 'completada'
    and c.fecha_hora >= p_fecha_inicio
    and c.fecha_hora <= p_fecha_fin
  group by c.cliente_id, p.nombre
  order by cantidad_citas desc, monto_total desc
  limit 20;
end;
$$;


ALTER FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_reporte_ingresos_detallado(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(total_ingresos numeric, total_descuentos numeric, citas_completadas integer, citas_canceladas integer, ticket_promedio numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_ingresos numeric := 0;
  v_descuentos numeric := 0;
  v_completadas integer := 0;
  v_canceladas integer := 0;
  v_ticket numeric := 0;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar los reportes de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  select
    coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0),
    coalesce(sum(c.descuento_aplicado) filter (where c.estado = 'completada'), 0),
    count(*) filter (where c.estado = 'completada')::integer,
    count(*) filter (where c.estado in ('cancelada', 'no_asistio'))::integer
  into v_ingresos, v_descuentos, v_completadas, v_canceladas
  from public.citas c
  where c.barberia_id = v_barberia_id
    and c.fecha_hora >= p_fecha_inicio
    and c.fecha_hora <= p_fecha_fin;

  if v_completadas > 0 then
    v_ticket := round(v_ingresos / v_completadas, 2);
  else
    v_ticket := 0;
  end if;

  return query
  select v_ingresos, v_descuentos, v_completadas, v_canceladas, v_ticket;
end;
$$;


ALTER FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_reporte_por_barbero(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(barbero_id uuid, barbero_nombre text, cantidad_citas integer, ingresos_totales numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar los reportes de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    b.id as barbero_id,
    coalesce(p.nombre, 'Barbero') as barbero_nombre,
    count(c.id)::integer as cantidad_citas,
    coalesce(sum(c.precio_cobrado), 0) as ingresos_totales
  from public.barberos b
  left join public.perfiles p on p.id = b.perfil_id
  left join public.citas c
    on c.barbero_id = b.id
   and c.estado = 'completada'
   and c.fecha_hora >= p_fecha_inicio
   and c.fecha_hora <= p_fecha_fin
  where b.barberia_id = v_barberia_id
  group by b.id, p.nombre
  order by ingresos_totales desc, cantidad_citas desc;
end;
$$;


ALTER FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_reporte_por_servicio(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_reporte_por_servicio(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(servicio_id uuid, servicio_nombre text, cantidad_citas integer, ingresos_totales numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar los reportes de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    s.id as servicio_id,
    s.nombre as servicio_nombre,
    count(c.id)::integer as cantidad_citas,
    coalesce(sum(c.precio_cobrado), 0) as ingresos_totales
  from public.servicios s
  left join public.citas c
    on c.servicio_id = s.id
   and c.estado = 'completada'
   and c.fecha_hora >= p_fecha_inicio
   and c.fecha_hora <= p_fecha_fin
  where s.barberia_id = v_barberia_id
  group by s.id, s.nombre
  order by ingresos_totales desc, cantidad_citas desc;
end;
$$;


ALTER FUNCTION public.obtener_reporte_por_servicio(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_resumen_ingresos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_resumen_ingresos() RETURNS TABLE(ingresos_hoy numeric, ingresos_mes numeric, ingresos_anio numeric, citas_hoy integer, ingresos_ayer numeric, citas_ayer integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_hoy_inicio timestamptz;
  v_hoy_fin timestamptz;
  v_ayer_inicio timestamptz;
  v_mes_inicio timestamptz;
  v_mes_fin timestamptz;
  v_anio_inicio timestamptz;
  v_anio_fin timestamptz;
  v_scan_inicio timestamptz;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar el resumen de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  v_hoy_inicio := date_trunc('day', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_hoy_fin := v_hoy_inicio + interval '1 day';
  v_ayer_inicio := v_hoy_inicio - interval '1 day';

  v_mes_inicio := date_trunc('month', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_mes_fin := v_mes_inicio + interval '1 month';

  v_anio_inicio := date_trunc('year', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_anio_fin := v_anio_inicio + interval '1 year';

  -- "Ayer" puede caer en el año calendario ANTERIOR (si hoy es 1 de enero),
  -- fuera del rango [v_anio_inicio, v_anio_fin) que hasta ahora acotaba todo
  -- el scan (ya cubría "hoy" y "este mes" sin este caso límite) -- mismo
  -- caso límite que ya resuelve obtener_resumen_ingresos_barbero (0044) con
  -- least(semana_inicio, mes_inicio). Se amplía solo el límite INFERIOR del
  -- scan; ingresos_anio conserva su propio filtro exacto [v_anio_inicio,
  -- v_anio_fin) más abajo para no arrastrar de más si el scan crece.
  v_scan_inicio := least(v_anio_inicio, v_ayer_inicio);

  -- Un solo scan lógico sobre citas (acotado a v_scan_inicio..v_anio_fin)
  -- con "filter" por métrica en vez de selects sueltos, mismo patrón que la
  -- versión original de esta función (0030): cada rango es un acumulador
  -- independiente, ninguno se calcula a partir de otro.
  return query
  select
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
    ), 0) as ingresos_hoy,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_mes_inicio and c.fecha_hora < v_mes_fin
    ), 0) as ingresos_mes,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_anio_inicio and c.fecha_hora < v_anio_fin
    ), 0) as ingresos_anio,
    count(*) filter (
      where c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
        and c.estado not in ('cancelada', 'no_asistio')
    )::integer as citas_hoy,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_ayer_inicio and c.fecha_hora < v_hoy_inicio
    ), 0) as ingresos_ayer,
    count(*) filter (
      where c.fecha_hora >= v_ayer_inicio and c.fecha_hora < v_hoy_inicio
        and c.estado not in ('cancelada', 'no_asistio')
    )::integer as citas_ayer
  from public.citas c
  where c.barberia_id = v_barberia_id
    and c.fecha_hora >= v_scan_inicio
    and c.fecha_hora < v_anio_fin;
end;
$$;


ALTER FUNCTION public.obtener_resumen_ingresos() OWNER TO postgres;

--
-- Name: obtener_resumen_ingresos_barbero(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_resumen_ingresos_barbero() RETURNS TABLE(ingresos_hoy numeric, ingresos_semana numeric, ingresos_mes numeric, citas_hoy integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_perfil_id uuid := auth.uid();
  v_hoy_inicio timestamptz;
  v_hoy_fin timestamptz;
  v_semana_inicio timestamptz;
  v_semana_fin timestamptz;
  v_mes_inicio timestamptz;
  v_mes_fin timestamptz;
  v_scan_desde timestamptz;
begin
  if v_perfil_id is null then
    raise exception 'Sesión no iniciada.';
  end if;

  v_hoy_inicio := date_trunc('day', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_hoy_fin := v_hoy_inicio + interval '1 day';

  v_semana_inicio := date_trunc('week', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_semana_fin := v_semana_inicio + interval '1 week';

  v_mes_inicio := date_trunc('month', now() at time zone 'America/La_Paz') at time zone 'America/La_Paz';
  v_mes_fin := v_mes_inicio + interval '1 month';

  v_scan_desde := least(v_semana_inicio, v_mes_inicio);

  return query
  select
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
    ), 0) as ingresos_hoy,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_semana_inicio and c.fecha_hora < v_semana_fin
    ), 0) as ingresos_semana,
    coalesce(sum(c.precio_cobrado) filter (
      where c.estado = 'completada'
        and c.fecha_hora >= v_mes_inicio and c.fecha_hora < v_mes_fin
    ), 0) as ingresos_mes,
    count(*) filter (
      where c.fecha_hora >= v_hoy_inicio and c.fecha_hora < v_hoy_fin
        and c.estado not in ('cancelada', 'no_asistio')
    )::integer as citas_hoy
  from public.citas c
  where c.barbero_id in (
    select b.id from public.barberos b where b.perfil_id = v_perfil_id
  )
  and c.fecha_hora >= v_scan_desde;
end;
$$;


ALTER FUNCTION public.obtener_resumen_ingresos_barbero() OWNER TO postgres;

--
-- Name: obtener_rol_actual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_rol_actual() RETURNS public.rol_usuario
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select rol from public.perfiles where id = auth.uid();
$$;


ALTER FUNCTION public.obtener_rol_actual() OWNER TO postgres;

--
-- Name: obtener_sucursal_id_actual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_sucursal_id_actual() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select sucursal_id from public.perfiles where id = auth.uid();
$$;


ALTER FUNCTION public.obtener_sucursal_id_actual() OWNER TO postgres;

--
-- Name: obtener_tasa_ausentismo_por_barbero(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_tasa_ausentismo_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) RETURNS TABLE(barbero_id uuid, barbero_nombre text, total_citas bigint, canceladas bigint, no_asistio bigint, tasa_ausentismo numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar este reporte.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  return query
  select
    b.id as barbero_id,
    coalesce(p.nombre, 'Barbero') as barbero_nombre,
    count(c.id) as total_citas,
    count(*) filter (where c.estado = 'cancelada') as canceladas,
    count(*) filter (where c.estado = 'no_asistio') as no_asistio,
    round(
      count(*) filter (where c.estado in ('cancelada', 'no_asistio'))::numeric
        / nullif(count(c.id), 0) * 100,
      1
    ) as tasa_ausentismo
  from public.barberos b
  left join public.perfiles p on p.id = b.perfil_id
  join public.citas c
    on c.barbero_id = b.id
   and c.fecha_hora >= p_fecha_inicio
   and c.fecha_hora <= p_fecha_fin
  where b.barberia_id = v_barberia_id
  group by b.id, p.nombre
  order by tasa_ausentismo desc;
end;
$$;


ALTER FUNCTION public.obtener_tasa_ausentismo_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- Name: obtener_tendencia_ingresos(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_tendencia_ingresos(p_periodo text) RETURNS TABLE(fecha date, monto numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_hoy_local date;
  v_mes_inicio_local date;
  v_anio_inicio_local date;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede consultar la tendencia de ingresos.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  v_hoy_local := (now() at time zone 'America/La_Paz')::date;
  v_mes_inicio_local := date_trunc('month', v_hoy_local::timestamp)::date;
  v_anio_inicio_local := date_trunc('year', v_hoy_local::timestamp)::date;

  if p_periodo = 'semana' then
    return query
    select
      d.dia::date as fecha,
      coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as monto
    from generate_series(
      (v_hoy_local - 6)::timestamp,
      v_hoy_local::timestamp,
      interval '1 day'
    ) as d(dia)
    left join public.citas c
      on c.barberia_id = v_barberia_id
     and c.estado = 'completada'
     and c.fecha_hora >= (d.dia at time zone 'America/La_Paz')
     and c.fecha_hora < ((d.dia + interval '1 day') at time zone 'America/La_Paz')
    group by d.dia
    order by d.dia;
  elsif p_periodo = 'mes' then
    return query
    select
      d.dia::date as fecha,
      coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as monto
    from generate_series(
      v_mes_inicio_local::timestamp,
      v_hoy_local::timestamp,
      interval '1 day'
    ) as d(dia)
    left join public.citas c
      on c.barberia_id = v_barberia_id
     and c.estado = 'completada'
     and c.fecha_hora >= (d.dia at time zone 'America/La_Paz')
     and c.fecha_hora < ((d.dia + interval '1 day') at time zone 'America/La_Paz')
    group by d.dia
    order by d.dia;
  elsif p_periodo = 'anio' then
    return query
    select
      m.mes::date as fecha,
      coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as monto
    from generate_series(
      v_anio_inicio_local::timestamp,
      v_mes_inicio_local::timestamp,
      interval '1 month'
    ) as m(mes)
    left join public.citas c
      on c.barberia_id = v_barberia_id
     and c.estado = 'completada'
     and c.fecha_hora >= (m.mes at time zone 'America/La_Paz')
     and c.fecha_hora < ((m.mes + interval '1 month') at time zone 'America/La_Paz')
    group by m.mes
    order by m.mes;
  else
    raise exception 'Periodo de tendencia inválido: %. Use semana, mes o anio.', p_periodo;
  end if;
end;
$$;


ALTER FUNCTION public.obtener_tendencia_ingresos(p_periodo text) OWNER TO postgres;

--
-- Name: obtener_usos_promocion_por_cliente(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_usos_promocion_por_cliente(p_promocion_id uuid) RETURNS TABLE(cliente_id uuid, cliente_nombre text, veces_usada integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'No tienes permiso para ver esta información.';
  end if;

  select barberia_id into v_barberia_id
  from public.promociones
  where id = p_promocion_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'Promoción no encontrada.';
  end if;

  return query
  select c.cliente_id, p.nombre, count(*)::integer
  from public.citas c
  join public.perfiles p on p.id = c.cliente_id
  where c.promocion_id = p_promocion_id
    and c.estado in ('pendiente', 'confirmada', 'completada')
  group by c.cliente_id, p.nombre
  order by count(*) desc;
end;
$$;


ALTER FUNCTION public.obtener_usos_promocion_por_cliente(p_promocion_id uuid) OWNER TO postgres;

--
-- Name: rechazar_pago(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rechazar_pago(p_pago_id uuid) RETURNS public.pagos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_pago pagos;
begin
  if not (
    es_superadmin()
    or (
      es_admin_o_superior()
      and exists (
        select 1 from public.pagos p
        where p.id = p_pago_id and p.barberia_id = obtener_barberia_id_actual()
      )
    )
  ) then
    raise exception 'No tienes permiso para verificar este pago.';
  end if;

  update public.pagos
  set estado = 'rechazado', verificado_por = auth.uid()
  where id = p_pago_id and estado = 'por_verificar'
  returning * into v_pago;

  if not found then
    raise exception 'Este pago no está pendiente de verificación.';
  end if;

  return v_pago;
end;
$$;


ALTER FUNCTION public.rechazar_pago(p_pago_id uuid) OWNER TO postgres;

--
-- Name: promociones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promociones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    imagen text,
    descuento numeric(5,2),
    fecha_inicio date,
    fecha_fin date,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    servicio_id uuid,
    tipo_descuento text DEFAULT 'porcentaje'::text NOT NULL,
    servicios_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    nombres_servicios jsonb DEFAULT '[]'::jsonb NOT NULL,
    limite_usos_por_cliente integer,
    capacidad_maxima integer,
    cliente_exclusivo_id uuid,
    CONSTRAINT promociones_capacidad_maxima_check CHECK ((capacidad_maxima > 0)),
    CONSTRAINT promociones_limite_usos_por_cliente_check CHECK ((limite_usos_por_cliente > 0)),
    CONSTRAINT promociones_tipo_descuento_check CHECK ((tipo_descuento = ANY (ARRAY['porcentaje'::text, 'monto_fijo'::text])))
);


ALTER TABLE public.promociones OWNER TO postgres;

--
-- Name: reclamar_premio_fidelidad(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reclamar_premio_fidelidad(p_programa_id uuid) RETURNS public.promociones
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_programa record;
  v_progreso_actual integer;
  v_promo promociones;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'No tienes una barbería asignada.';
  end if;

  select * into v_programa
  from public.programas_fidelidad
  where id = p_programa_id
    and barberia_id = v_barberia_id
    and activo = true
    and (fecha_inicio is null or fecha_inicio <= current_date)
    and (fecha_fin is null or fecha_fin >= current_date);

  if v_programa is null then
    raise exception 'Programa de fidelidad no encontrado o inactivo.';
  end if;

  perform pg_advisory_xact_lock(hashtext('fidelidad:' || auth.uid()::text || ':' || p_programa_id::text));

  select coalesce(count(*)::integer, 0) into v_progreso_actual
  from public.citas c
  where c.cliente_id = auth.uid()
    and c.estado = 'completada'
    and c.servicio_id in (
      select jsonb_array_elements_text(v_programa.servicios_ids)::uuid
    )
    and c.fecha_hora > coalesce(
      (
        select max(rf.reclamado_en)
        from public.reclamaciones_fidelidad rf
        where rf.programa_id = p_programa_id and rf.cliente_id = auth.uid()
      ),
      v_programa.creado_en
    );

  if v_progreso_actual < v_programa.meta_citas then
    raise exception 'Todavía no alcanzaste la meta de este programa.';
  end if;

  insert into public.promociones (
    barberia_id, titulo, tipo_descuento, descuento, servicio_id,
    servicios_ids, activo, fecha_fin, cliente_exclusivo_id
  ) values (
    v_barberia_id,
    v_programa.titulo || ' - Premio',
    'porcentaje',
    100,
    (v_programa.servicios_ids ->> 0)::uuid,
    v_programa.servicios_ids,
    true,
    v_programa.fecha_fin,
    auth.uid()
  ) returning * into v_promo;

  insert into public.reclamaciones_fidelidad (
    programa_id, cliente_id, promocion_generada_id
  ) values (p_programa_id, auth.uid(), v_promo.id);

  return v_promo;
end;
$$;


ALTER FUNCTION public.reclamar_premio_fidelidad(p_programa_id uuid) OWNER TO postgres;

--
-- Name: reemplazar_horarios_barbero(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reemplazar_horarios_barbero(p_barbero_id uuid, p_horarios jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  select barberia_id into v_barberia_id
  from public.barberos
  where id = p_barbero_id;

  if v_barberia_id is null then
    raise exception 'Barbero no encontrado.';
  end if;

  -- Sin security definer: las políticas RLS de horarios_barbero_escritura
  -- (admin de la barbería o el propio barbero) siguen aplicando al llamador real.
  delete from public.horarios_barbero where barbero_id = p_barbero_id;

  if jsonb_array_length(p_horarios) > 0 then
    insert into public.horarios_barbero (barbero_id, barberia_id, dia_semana, hora_inicio, hora_fin)
    select
      p_barbero_id,
      v_barberia_id,
      (h ->> 'dia_semana')::smallint,
      (h ->> 'hora_inicio')::time,
      (h ->> 'hora_fin')::time
    from jsonb_array_elements(p_horarios) as h;
  end if;
end;
$$;


ALTER FUNCTION public.reemplazar_horarios_barbero(p_barbero_id uuid, p_horarios jsonb) OWNER TO postgres;

--
-- Name: reportes_insumo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reportes_insumo (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    insumo_id uuid NOT NULL,
    tipo public.tipo_reporte_insumo NOT NULL,
    descripcion text,
    url_foto text,
    estado public.estado_reporte_insumo DEFAULT 'pendiente'::public.estado_reporte_insumo NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    cantidad integer DEFAULT 1 NOT NULL,
    revisado_por uuid,
    CONSTRAINT reportes_insumo_cantidad_check CHECK ((cantidad > 0))
);


ALTER TABLE public.reportes_insumo OWNER TO postgres;

--
-- Name: reportar_insumo(uuid, public.tipo_reporte_insumo, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reportar_insumo(p_insumo_id uuid, p_tipo public.tipo_reporte_insumo, p_cantidad integer, p_descripcion text, p_url_foto text) RETURNS public.reportes_insumo
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barbero_id uuid;
  v_barberia_id uuid;
  v_reporte reportes_insumo;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  -- barberos tiene unique(perfil_id, sucursal_id), no unique(perfil_id): una
  -- misma persona puede tener varias filas si trabaja en mas de una sucursal.
  -- Por eso no resolvemos "cual es MI barbero_id" en abstracto (un
  -- select...into con varias filas coincidentes no falla, toma una en orden
  -- no especificado y podria ser la de la sucursal equivocada) -- resolvemos
  -- directo la fila de insumos_barbero de ESE insumo que le pertenece a la
  -- persona autenticada, sin ambiguedad posible.
  select ib.barbero_id, b.barberia_id into v_barbero_id, v_barberia_id
  from public.insumos_barbero ib
  join public.barberos b on b.id = ib.barbero_id
  where ib.insumo_id = p_insumo_id and b.perfil_id = auth.uid()
  limit 1;

  if v_barbero_id is null then
    raise exception 'No tenés esa cantidad de insumo asignada.';
  end if;

  if p_cantidad <= 0 then
    raise exception 'La cantidad debe ser mayor a cero.';
  end if;

  update public.insumos_barbero
  set cantidad_asignada = cantidad_asignada - p_cantidad
  where barbero_id = v_barbero_id
    and insumo_id = p_insumo_id
    and cantidad_asignada >= p_cantidad;

  if not found then
    raise exception 'No tenés esa cantidad de insumo asignada.';
  end if;

  insert into public.reportes_insumo (
    barberia_id, barbero_id, insumo_id, tipo, cantidad, descripcion, url_foto, estado
  )
  values (
    v_barberia_id, v_barbero_id, p_insumo_id, p_tipo, p_cantidad, p_descripcion, p_url_foto, 'pendiente'
  )
  returning * into v_reporte;

  return v_reporte;
end;
$$;


ALTER FUNCTION public.reportar_insumo(p_insumo_id uuid, p_tipo public.tipo_reporte_insumo, p_cantidad integer, p_descripcion text, p_url_foto text) OWNER TO postgres;

--
-- Name: reservar_cita(uuid, uuid, uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_barbero_id uuid, p_fecha_hora timestamp with time zone) RETURNS public.citas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_barbero_id uuid;
  v_cita citas;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null or v_barberia_id is distinct from obtener_barberia_id_actual() then
    raise exception 'No tienes permiso para reservar en esta sucursal.';
  end if;

  -- sv.barberia_id = v_barberia_id: mismo motivo que en
  -- obtener_horarios_disponibles -- sin esto se podria reservar un servicio
  -- (y su duracion_min) de otra barberia.
  select sv.duracion_min into v_duracion_min
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  -- Granularidad de dia (no de instante exacto): dos reservas del mismo
  -- barbero con horas de inicio distintas pero que se solapan (ej. 09:00 y
  -- 09:15, ambas de 30 min) deben serializarse entre si. Si el lock fuera
  -- por instante exacto, tomarian keys distintas y correrian en paralelo
  -- bajo READ COMMITTED -- ninguna veria el insert no confirmado de la
  -- otra, y el unique(barbero_id, fecha_hora) de citas no las frena porque
  -- fecha_hora difiere. Mismo principio que el lock por sucursal+dia de
  -- crear_turno (0008b).
  perform pg_advisory_xact_lock(hashtext(p_sucursal_id::text || (p_fecha_hora::date)::text));

  if p_barbero_id is not null then
    -- El barbero explicito debe pertenecer a esta sucursal/tenant y estar
    -- activo -- la rama "cualquiera" ya lo exige (b.sucursal_id = ... and
    -- b.activo = true) pero esta rama no lo chequeaba. Mismo mensaje
    -- generico que el de "no disponible" para no revelar si el barbero
    -- existe, esta inactivo o es de otra sucursal (anti-enumeracion).
    if not exists (
      select 1
      from public.barberos b
      where b.id = p_barbero_id
        and b.sucursal_id = p_sucursal_id
        and b.activo = true
    ) then
      raise exception 'Ese horario ya no está disponible. Elegí otro.';
    end if;

    -- Re-chequeo dentro del lock: pudo haberse ocupado entre que el cliente
    -- vio la lista de horarios y confirmo la reserva. Incluye 'completada'
    -- ademas de 'pendiente'/'confirmada' -- mismo motivo que en
    -- obtener_horarios_disponibles, para quedar de acuerdo con
    -- idx_citas_barbero_fecha_hora_activa (0024) y no reventar con
    -- unique_violation en el insert final.
    if exists (
      select 1
      from public.citas c
      where c.barbero_id = p_barbero_id
        and c.estado in ('pendiente', 'confirmada', 'completada')
        and p_fecha_hora < c.fecha_hora + (c.duracion_min || ' minutes')::interval
        and p_fecha_hora + (v_duracion_min || ' minutes')::interval > c.fecha_hora
    ) then
      raise exception 'Ese horario ya no está disponible. Elegí otro.';
    end if;

    v_barbero_id := p_barbero_id;
  else
    select b.id into v_barbero_id
    from public.barberos b
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and p_fecha_hora < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and p_fecha_hora + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    limit 1;

    if v_barbero_id is null then
      raise exception 'Ese horario ya no está disponible. Elegí otro.';
    end if;
  end if;

  insert into public.citas (
    barberia_id, sucursal_id, barbero_id, cliente_id, servicio_id,
    fecha_hora, duracion_min, estado
  ) values (
    v_barberia_id, p_sucursal_id, v_barbero_id, auth.uid(), p_servicio_id,
    p_fecha_hora, v_duracion_min, 'pendiente'
  ) returning * into v_cita;

  return v_cita;
end;
$$;


ALTER FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_barbero_id uuid, p_fecha_hora timestamp with time zone) OWNER TO postgres;

--
-- Name: reservar_cita(uuid, uuid, timestamp with time zone, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_fecha_hora timestamp with time zone, p_barbero_id uuid DEFAULT NULL::uuid, p_promocion_id uuid DEFAULT NULL::uuid) RETURNS public.citas
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
  v_duracion_min integer;
  v_precio_original numeric(10, 2);
  v_precio_cobrado numeric(10, 2);
  v_descuento numeric(10, 2) := 0;
  v_barbero_id uuid;
  v_cita citas;
  v_promo record;
  v_es_combo boolean;
  v_usos_previos integer;
  v_usos_totales integer;
begin
  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select s.barberia_id into v_barberia_id
  from public.sucursales s
  where s.id = p_sucursal_id;

  if v_barberia_id is null then
    raise exception 'Sucursal no encontrada.';
  end if;

  if not es_cliente_o_superior(v_barberia_id) then
    raise exception 'No tienes permiso para reservar en esta sucursal.';
  end if;

  select sv.duracion_min, sv.precio into v_duracion_min, v_precio_original
  from public.servicios sv
  where sv.id = p_servicio_id
    and sv.barberia_id = v_barberia_id;

  if v_duracion_min is null then
    raise exception 'Servicio no encontrado.';
  end if;

  v_precio_cobrado := v_precio_original;

  if p_promocion_id is not null then
    select * into v_promo
    from public.promociones
    where id = p_promocion_id
      and barberia_id = v_barberia_id
      and activo = true
      and (fecha_inicio is null or fecha_inicio <= current_date)
      and (fecha_fin is null or fecha_fin >= current_date);

    if v_promo is null then
      raise exception 'La promoción seleccionada ya no está disponible o ha vencido.';
    end if;

    if v_promo.cliente_exclusivo_id is not null and v_promo.cliente_exclusivo_id != auth.uid() then
      raise exception 'Esta promoción no está disponible para tu cuenta.';
    end if;

    if v_promo.limite_usos_por_cliente is not null then
      perform pg_advisory_xact_lock(hashtext('limite_promo:' || auth.uid()::text || ':' || p_promocion_id::text));

      select count(*) into v_usos_previos
      from public.citas c
      where c.promocion_id = p_promocion_id
        and c.cliente_id = auth.uid()
        and c.estado in ('pendiente', 'confirmada', 'completada');

      if v_usos_previos >= v_promo.limite_usos_por_cliente then
        raise exception 'Ya alcanzaste el límite de usos de esta promoción.';
      end if;
    end if;

    if v_promo.capacidad_maxima is not null then
      perform pg_advisory_xact_lock(hashtext('capacidad_promo:' || p_promocion_id::text));

      select count(*) into v_usos_totales
      from public.citas c
      where c.promocion_id = p_promocion_id
        and c.estado in ('pendiente', 'confirmada', 'completada');

      if v_usos_totales >= v_promo.capacidad_maxima then
        raise exception 'Esta promoción ya alcanzó su capacidad máxima de usos.';
      end if;
    end if;

    v_es_combo := v_promo.servicios_ids is not null
      and jsonb_array_length(v_promo.servicios_ids) > 1;

    if v_es_combo then
      if (v_promo.servicios_ids ->> 0)::uuid != p_servicio_id then
        raise exception 'La promoción no aplica a este servicio.';
      end if;

      select
        coalesce(sum(sv.duracion_min), 0),
        coalesce(sum(sv.precio), 0)
      into v_duracion_min, v_precio_original
      from public.servicios sv
      where sv.id in (
        select jsonb_array_elements_text(v_promo.servicios_ids)::uuid
      )
      and sv.barberia_id = v_barberia_id;

      if v_duracion_min = 0 then
        raise exception 'Servicio no encontrado.';
      end if;

      v_precio_cobrado := v_precio_original;
    elsif v_promo.servicio_id is not null and v_promo.servicio_id != p_servicio_id then
      raise exception 'La promoción no aplica a este servicio.';
    end if;

    if v_promo.tipo_descuento = 'porcentaje' then
      v_descuento := (v_precio_original * v_promo.descuento) / 100.0;
    else
      v_descuento := v_promo.descuento;
    end if;

    if v_descuento > v_precio_original then
      v_descuento := v_precio_original;
    end if;

    v_precio_cobrado := v_precio_original - v_descuento;
  end if;

  perform pg_advisory_xact_lock(hashtext(p_sucursal_id::text || (p_fecha_hora::date)::text));

  if p_barbero_id is not null then
    if not exists (
      select 1
      from public.barberos b
      where b.id = p_barbero_id
        and b.sucursal_id = p_sucursal_id
        and b.activo = true
    ) then
      raise exception 'Ese horario ya no está disponible. Elegí otro.';
    end if;

    if exists (
      select 1
      from public.citas c
      where c.barbero_id = p_barbero_id
        and c.estado in ('pendiente', 'confirmada', 'completada')
        and p_fecha_hora < c.fecha_hora + (c.duracion_min || ' minutes')::interval
        and p_fecha_hora + (v_duracion_min || ' minutes')::interval > c.fecha_hora
    ) then
      raise exception 'Ese horario ya no está disponible. Elegí otro.';
    end if;

    v_barbero_id := p_barbero_id;
  else
    select b.id into v_barbero_id
    from public.barberos b
    where b.sucursal_id = p_sucursal_id
      and b.activo = true
      and not exists (
        select 1
        from public.citas c
        where c.barbero_id = b.id
          and c.estado in ('pendiente', 'confirmada', 'completada')
          and p_fecha_hora < c.fecha_hora + (c.duracion_min || ' minutes')::interval
          and p_fecha_hora + (v_duracion_min || ' minutes')::interval > c.fecha_hora
      )
    limit 1;

    if v_barbero_id is null then
      raise exception 'Ese horario ya no está disponible. Elegí otro.';
    end if;
  end if;

  insert into public.citas (
    barberia_id, sucursal_id, barbero_id, cliente_id, servicio_id,
    fecha_hora, duracion_min, estado, precio_cobrado, promocion_id, descuento_aplicado
  ) values (
    v_barberia_id, p_sucursal_id, v_barbero_id, auth.uid(), p_servicio_id,
    p_fecha_hora, v_duracion_min, 'pendiente', v_precio_cobrado, p_promocion_id, v_descuento
  ) returning * into v_cita;

  return v_cita;
end;
$$;


ALTER FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_fecha_hora timestamp with time zone, p_barbero_id uuid, p_promocion_id uuid) OWNER TO postgres;

--
-- Name: revisar_reporte_insumo(uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.revisar_reporte_insumo(p_reporte_id uuid, p_aprobar boolean) RETURNS public.reportes_insumo
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_reporte reportes_insumo;
begin
  if not es_admin_o_superior() then
    raise exception 'No tenés permiso para revisar reportes.';
  end if;

  update public.reportes_insumo
  set estado = case when p_aprobar then 'atendido' else 'rechazado' end,
      revisado_por = auth.uid()
  where id = p_reporte_id
    and barberia_id = obtener_barberia_id_actual()
    and estado = 'pendiente'
  returning * into v_reporte;

  if not found then
    raise exception 'Este reporte ya fue revisado.';
  end if;

  if not p_aprobar then
    insert into public.insumos_barbero (barberia_id, barbero_id, insumo_id, cantidad_asignada)
    values (v_reporte.barberia_id, v_reporte.barbero_id, v_reporte.insumo_id, v_reporte.cantidad)
    on conflict (barbero_id, insumo_id)
    do update set cantidad_asignada = insumos_barbero.cantidad_asignada + excluded.cantidad_asignada;
  end if;

  return v_reporte;
end;
$$;


ALTER FUNCTION public.revisar_reporte_insumo(p_reporte_id uuid, p_aprobar boolean) OWNER TO postgres;

--
-- Name: revocar_secretaria(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.revocar_secretaria(p_perfil_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede quitar el acceso de una secretaria.';
  end if;

  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  if not exists (
    select 1 from public.perfiles
    where id = p_perfil_id and barberia_id = v_barberia_id and rol = 'secretaria'
  ) then
    raise exception 'No se encontró esa secretaria en tu barbería.';
  end if;

  perform set_config('app.bypass_escalada_privilegios', 'true', true);

  update public.perfiles
  set rol = 'cliente',
      sucursal_id = null
  where id = p_perfil_id;
end;
$$;


ALTER FUNCTION public.revocar_secretaria(p_perfil_id uuid) OWNER TO postgres;

--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION public.rls_auto_enable() OWNER TO postgres;

--
-- Name: subir_comprobante_pago(uuid, numeric, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.subir_comprobante_pago(p_cita_id uuid, p_monto numeric, p_url_comprobante text) RETURNS public.pagos
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_cita citas;
  v_pago pagos;
begin
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto a pagar debe ser mayor a cero.';
  end if;

  if auth.uid() is null then
    raise exception 'Sesión no iniciada.';
  end if;

  select * into v_cita from public.citas where id = p_cita_id;
  if v_cita is null or v_cita.cliente_id is distinct from auth.uid() then
    raise exception 'Cita no encontrada.';
  end if;

  if v_cita.estado != 'pendiente' then
    raise exception 'Esta cita ya no está pendiente.';
  end if;

  update public.pagos
  set estado = 'por_verificar', url_comprobante = p_url_comprobante, monto = p_monto,
      fecha = now(), verificado_por = null
  where cita_id = p_cita_id and estado != 'confirmado'
  returning * into v_pago;

  if not found then
    -- si no encontro fila para actualizar, puede ser porque no existe pago
    -- todavia (insertar nuevo) o porque el pago existente ya esta
    -- 'confirmado' (no se debe tocar). Distinguir los dos casos:
    if exists (select 1 from public.pagos where cita_id = p_cita_id and estado = 'confirmado') then
      raise exception 'Esta cita ya tiene un pago confirmado.';
    end if;

    insert into public.pagos (barberia_id, cita_id, monto, metodo, estado, url_comprobante)
    values (v_cita.barberia_id, p_cita_id, p_monto, 'qr_manual', 'por_verificar', p_url_comprobante)
    returning * into v_pago;
  end if;

  return v_pago;
end;
$$;


ALTER FUNCTION public.subir_comprobante_pago(p_cita_id uuid, p_monto numeric, p_url_comprobante text) OWNER TO postgres;

--
-- Name: validar_permiso_turno(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_permiso_turno(p_sucursal_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_barberia_id uuid;
begin
  select barberia_id into v_barberia_id from public.sucursales where id = p_sucursal_id;

  if not (
    v_barberia_id is not null
    and (
      es_superadmin()
      or (
        v_barberia_id = obtener_barberia_id_actual()
        and (es_admin_o_superior() or p_sucursal_id = obtener_sucursal_id_actual())
      )
    )
  ) then
    raise exception 'No tienes permiso para registrar un turno en esta sucursal.';
  end if;

  return v_barberia_id;
end;
$$;


ALTER FUNCTION public.validar_permiso_turno(p_sucursal_id uuid) OWNER TO postgres;

--
-- Name: accesos_admin_uso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accesos_admin_uso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    perfil_id uuid NOT NULL,
    ruta text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.accesos_admin_uso OWNER TO postgres;

--
-- Name: barberias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.barberias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    slogan text,
    url_logo text,
    plan_saas text DEFAULT 'basico'::text NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.barberias OWNER TO postgres;

--
-- Name: barberos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.barberos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    perfil_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    barberia_id uuid NOT NULL,
    especialidades text[],
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    nivel text,
    descripcion text,
    CONSTRAINT barberos_nivel_check CHECK ((nivel = ANY (ARRAY['junior'::text, 'senior'::text, 'master'::text])))
);


ALTER TABLE public.barberos OWNER TO postgres;

--
-- Name: clientes_walkin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientes_walkin (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    nombre text NOT NULL,
    telefono text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.clientes_walkin OWNER TO postgres;

--
-- Name: configuraciones_barberia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuraciones_barberia (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    clave text NOT NULL,
    valor jsonb DEFAULT '{}'::jsonb NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.configuraciones_barberia OWNER TO postgres;

--
-- Name: horarios_barbero; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horarios_barbero (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barbero_id uuid NOT NULL,
    barberia_id uuid NOT NULL,
    dia_semana smallint NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT horarios_barbero_check CHECK ((hora_fin > hora_inicio)),
    CONSTRAINT horarios_barbero_dia_semana_check CHECK (((dia_semana >= 0) AND (dia_semana <= 6)))
);


ALTER TABLE public.horarios_barbero OWNER TO postgres;

--
-- Name: insignias_ranking_barberos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insignias_ranking_barberos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    programa_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    puesto integer NOT NULL,
    otorgada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT insignias_ranking_barberos_puesto_check CHECK ((puesto = ANY (ARRAY[1, 2, 3])))
);


ALTER TABLE public.insignias_ranking_barberos OWNER TO postgres;

--
-- Name: insumos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insumos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    nombre text NOT NULL,
    categoria text,
    stock integer DEFAULT 0 NOT NULL,
    stock_minimo integer DEFAULT 0 NOT NULL,
    costo_unitario numeric(10,2),
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT insumos_stock_check CHECK ((stock >= 0)),
    CONSTRAINT insumos_stock_minimo_check CHECK ((stock_minimo >= 0))
);


ALTER TABLE public.insumos OWNER TO postgres;

--
-- Name: perfiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.perfiles (
    id uuid NOT NULL,
    barberia_id uuid,
    rol public.rol_usuario DEFAULT 'cliente'::public.rol_usuario NOT NULL,
    nombre text,
    url_foto text,
    telefono text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    email text,
    sucursal_id uuid
);


ALTER TABLE public.perfiles OWNER TO postgres;

--
-- Name: programas_fidelidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.programas_fidelidad (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    titulo text NOT NULL,
    servicios_ids jsonb NOT NULL,
    meta_citas integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    CONSTRAINT programas_fidelidad_meta_citas_check CHECK ((meta_citas > 0))
);


ALTER TABLE public.programas_fidelidad OWNER TO postgres;

--
-- Name: reclamaciones_fidelidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reclamaciones_fidelidad (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    programa_id uuid NOT NULL,
    cliente_id uuid NOT NULL,
    promocion_generada_id uuid NOT NULL,
    reclamado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.reclamaciones_fidelidad OWNER TO postgres;

--
-- Name: servicios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.servicios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    nombre text NOT NULL,
    descripcion text,
    duracion_min integer NOT NULL,
    precio numeric(10,2) NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    url_imagen text,
    CONSTRAINT servicios_duracion_min_check CHECK ((duracion_min > 0)),
    CONSTRAINT servicios_precio_check CHECK ((precio >= (0)::numeric))
);


ALTER TABLE public.servicios OWNER TO postgres;

--
-- Name: sucursales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sucursales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    nombre text NOT NULL,
    direccion text,
    telefono text,
    horario_apertura time without time zone,
    horario_cierre time without time zone,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    url_imagen text,
    manager_nombre text,
    latitud double precision,
    longitud double precision
);


ALTER TABLE public.sucursales OWNER TO postgres;

--
-- Name: versiones_app; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versiones_app (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    version text NOT NULL,
    url_apk text NOT NULL,
    notas_cambios text,
    obligatoria boolean DEFAULT false NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.versiones_app OWNER TO postgres;

--
-- Name: vista_reportes_barberos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_reportes_barberos AS
 SELECT b.id AS barbero_id,
    COALESCE(p.nombre, 'Barbero'::text) AS barbero_nombre,
    count(c.id) AS cantidad_citas,
    COALESCE(sum(c.precio_cobrado), (0)::numeric) AS ingresos_totales
   FROM ((public.barberos b
     LEFT JOIN public.perfiles p ON ((p.id = b.perfil_id)))
     LEFT JOIN public.citas c ON (((c.barbero_id = b.id) AND (c.estado = 'completada'::public.estado_cita))))
  WHERE (b.barberia_id = public.obtener_barberia_unica_reportes_powerbi())
  GROUP BY b.id, p.nombre;


ALTER VIEW public.vista_reportes_barberos OWNER TO postgres;

--
-- Name: VIEW vista_reportes_barberos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vista_reportes_barberos IS 'Reportes Power BI: ingresos y cantidad de citas completadas por barbero, mismo criterio que obtener_reporte_por_barbero (0035) sin rango de fechas. Filtrada a la única barbería real (ver 0048).';


--
-- Name: vista_reportes_citas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_reportes_citas AS
 SELECT c.id AS cita_id,
    c.fecha_hora,
    c.estado,
    c.precio_cobrado,
    c.descuento_aplicado,
    s.nombre AS servicio_nombre,
    COALESCE(p.nombre, 'Barbero'::text) AS barbero_nombre,
    suc.nombre AS sucursal_nombre
   FROM ((((public.citas c
     LEFT JOIN public.servicios s ON ((s.id = c.servicio_id)))
     LEFT JOIN public.barberos b ON ((b.id = c.barbero_id)))
     LEFT JOIN public.perfiles p ON ((p.id = b.perfil_id)))
     LEFT JOIN public.sucursales suc ON ((suc.id = c.sucursal_id)))
  WHERE (c.barberia_id = public.obtener_barberia_unica_reportes_powerbi());


ALTER VIEW public.vista_reportes_citas OWNER TO postgres;

--
-- Name: VIEW vista_reportes_citas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vista_reportes_citas IS 'Reportes Power BI: una fila por cita, sin datos personales del cliente. Filtrada a la única barbería real del sistema (ver 0048). Security invoker=false (default de Postgres): corre con los privilegios del dueño de la vista, bypassando RLS de citas/servicios/barberos a propósito -- el where de arriba es la única frontera multi-tenant.';


--
-- Name: vista_reportes_servicios; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_reportes_servicios AS
 SELECT s.id AS servicio_id,
    s.nombre AS servicio_nombre,
    count(c.id) AS cantidad_citas,
    COALESCE(sum(c.precio_cobrado), (0)::numeric) AS ingresos_totales
   FROM (public.servicios s
     LEFT JOIN public.citas c ON (((c.servicio_id = s.id) AND (c.estado = 'completada'::public.estado_cita))))
  WHERE (s.barberia_id = public.obtener_barberia_unica_reportes_powerbi())
  GROUP BY s.id, s.nombre;


ALTER VIEW public.vista_reportes_servicios OWNER TO postgres;

--
-- Name: VIEW vista_reportes_servicios; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vista_reportes_servicios IS 'Reportes Power BI: ingresos y cantidad de citas completadas por servicio, mismo criterio que obtener_reporte_por_servicio (0035) sin rango de fechas. Filtrada a la única barbería real (ver 0048).';


--
-- Name: accesos_admin_uso accesos_admin_uso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accesos_admin_uso
    ADD CONSTRAINT accesos_admin_uso_pkey PRIMARY KEY (id);


--
-- Name: barberias barberias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barberias
    ADD CONSTRAINT barberias_pkey PRIMARY KEY (id);


--
-- Name: barberos barberos_perfil_id_sucursal_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barberos
    ADD CONSTRAINT barberos_perfil_id_sucursal_id_key UNIQUE (perfil_id, sucursal_id);


--
-- Name: barberos barberos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barberos
    ADD CONSTRAINT barberos_pkey PRIMARY KEY (id);


--
-- Name: citas citas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_pkey PRIMARY KEY (id);


--
-- Name: clientes_walkin clientes_walkin_barberia_id_telefono_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes_walkin
    ADD CONSTRAINT clientes_walkin_barberia_id_telefono_key UNIQUE (barberia_id, telefono);


--
-- Name: clientes_walkin clientes_walkin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes_walkin
    ADD CONSTRAINT clientes_walkin_pkey PRIMARY KEY (id);


--
-- Name: configuraciones_barberia configuraciones_barberia_barberia_id_clave_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuraciones_barberia
    ADD CONSTRAINT configuraciones_barberia_barberia_id_clave_key UNIQUE (barberia_id, clave);


--
-- Name: configuraciones_barberia configuraciones_barberia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuraciones_barberia
    ADD CONSTRAINT configuraciones_barberia_pkey PRIMARY KEY (id);


--
-- Name: horarios_barbero horarios_barbero_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horarios_barbero
    ADD CONSTRAINT horarios_barbero_pkey PRIMARY KEY (id);


--
-- Name: insignias_ranking_barberos insignias_ranking_barberos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insignias_ranking_barberos
    ADD CONSTRAINT insignias_ranking_barberos_pkey PRIMARY KEY (id);


--
-- Name: insignias_ranking_barberos insignias_ranking_barberos_programa_id_barbero_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insignias_ranking_barberos
    ADD CONSTRAINT insignias_ranking_barberos_programa_id_barbero_id_key UNIQUE (programa_id, barbero_id);


--
-- Name: insumos_barbero insumos_barbero_barbero_id_insumo_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos_barbero
    ADD CONSTRAINT insumos_barbero_barbero_id_insumo_id_key UNIQUE (barbero_id, insumo_id);


--
-- Name: insumos_barbero insumos_barbero_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos_barbero
    ADD CONSTRAINT insumos_barbero_pkey PRIMARY KEY (id);


--
-- Name: insumos insumos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_pkey PRIMARY KEY (id);


--
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id);


--
-- Name: perfiles perfiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfiles
    ADD CONSTRAINT perfiles_pkey PRIMARY KEY (id);


--
-- Name: programas_fidelidad programas_fidelidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_fidelidad
    ADD CONSTRAINT programas_fidelidad_pkey PRIMARY KEY (id);


--
-- Name: programas_ranking_barberos programas_ranking_barberos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_ranking_barberos
    ADD CONSTRAINT programas_ranking_barberos_pkey PRIMARY KEY (id);


--
-- Name: promociones promociones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promociones
    ADD CONSTRAINT promociones_pkey PRIMARY KEY (id);


--
-- Name: reclamaciones_fidelidad reclamaciones_fidelidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reclamaciones_fidelidad
    ADD CONSTRAINT reclamaciones_fidelidad_pkey PRIMARY KEY (id);


--
-- Name: reportes_insumo reportes_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes_insumo
    ADD CONSTRAINT reportes_insumo_pkey PRIMARY KEY (id);


--
-- Name: resenas resenas_cita_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resenas
    ADD CONSTRAINT resenas_cita_id_key UNIQUE (cita_id);


--
-- Name: resenas resenas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resenas
    ADD CONSTRAINT resenas_pkey PRIMARY KEY (id);


--
-- Name: servicios servicios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_pkey PRIMARY KEY (id);


--
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sucursales
    ADD CONSTRAINT sucursales_pkey PRIMARY KEY (id);


--
-- Name: turnos turnos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_pkey PRIMARY KEY (id);


--
-- Name: versiones_app versiones_app_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versiones_app
    ADD CONSTRAINT versiones_app_pkey PRIMARY KEY (id);


--
-- Name: idx_accesos_admin_uso_perfil_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_accesos_admin_uso_perfil_fecha ON public.accesos_admin_uso USING btree (perfil_id, creado_en DESC);


--
-- Name: idx_barberos_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_barberos_barberia ON public.barberos USING btree (barberia_id);


--
-- Name: idx_barberos_sucursal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_barberos_sucursal ON public.barberos USING btree (sucursal_id);


--
-- Name: idx_citas_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_citas_barberia ON public.citas USING btree (barberia_id);


--
-- Name: idx_citas_barbero_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_citas_barbero_fecha ON public.citas USING btree (barbero_id, fecha_hora);


--
-- Name: idx_citas_barbero_fecha_hora_activa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_citas_barbero_fecha_hora_activa ON public.citas USING btree (barbero_id, fecha_hora) WHERE (estado = ANY (ARRAY['pendiente'::public.estado_cita, 'confirmada'::public.estado_cita, 'completada'::public.estado_cita]));


--
-- Name: idx_citas_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_citas_cliente ON public.citas USING btree (cliente_id);


--
-- Name: idx_citas_pendientes; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_citas_pendientes ON public.citas USING btree (barberia_id) WHERE (estado = 'pendiente'::public.estado_cita);


--
-- Name: idx_clientes_walkin_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clientes_walkin_barberia ON public.clientes_walkin USING btree (barberia_id);


--
-- Name: idx_configuraciones_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_configuraciones_barberia ON public.configuraciones_barberia USING btree (barberia_id);


--
-- Name: idx_horarios_barbero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_horarios_barbero ON public.horarios_barbero USING btree (barbero_id);


--
-- Name: idx_insignias_ranking_barberos_barbero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insignias_ranking_barberos_barbero ON public.insignias_ranking_barberos USING btree (barbero_id);


--
-- Name: idx_insumos_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insumos_barberia ON public.insumos USING btree (barberia_id);


--
-- Name: idx_insumos_barbero_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insumos_barbero_barberia ON public.insumos_barbero USING btree (barberia_id);


--
-- Name: idx_insumos_sucursal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insumos_sucursal ON public.insumos USING btree (sucursal_id);


--
-- Name: idx_pagos_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagos_barberia ON public.pagos USING btree (barberia_id);


--
-- Name: idx_pagos_cita; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagos_cita ON public.pagos USING btree (cita_id);


--
-- Name: idx_perfiles_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_perfiles_barberia ON public.perfiles USING btree (barberia_id);


--
-- Name: idx_programas_fidelidad_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_programas_fidelidad_barberia ON public.programas_fidelidad USING btree (barberia_id);


--
-- Name: idx_programas_ranking_barberos_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_programas_ranking_barberos_barberia ON public.programas_ranking_barberos USING btree (barberia_id);


--
-- Name: idx_programas_ranking_barberos_sucursal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_programas_ranking_barberos_sucursal ON public.programas_ranking_barberos USING btree (sucursal_id);


--
-- Name: idx_promociones_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_promociones_barberia ON public.promociones USING btree (barberia_id);


--
-- Name: idx_reclamaciones_fidelidad_programa_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reclamaciones_fidelidad_programa_cliente ON public.reclamaciones_fidelidad USING btree (programa_id, cliente_id);


--
-- Name: idx_reportes_insumo_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reportes_insumo_barberia ON public.reportes_insumo USING btree (barberia_id);


--
-- Name: idx_resenas_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resenas_barberia ON public.resenas USING btree (barberia_id);


--
-- Name: idx_resenas_barbero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resenas_barbero ON public.resenas USING btree (barbero_id);


--
-- Name: idx_servicios_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_servicios_barberia ON public.servicios USING btree (barberia_id);


--
-- Name: idx_sucursales_barberia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sucursales_barberia ON public.sucursales USING btree (barberia_id);


--
-- Name: idx_turnos_cita_id_unico; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_turnos_cita_id_unico ON public.turnos USING btree (cita_id) WHERE (cita_id IS NOT NULL);


--
-- Name: idx_turnos_numero_unico_dia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_turnos_numero_unico_dia ON public.turnos USING btree (sucursal_id, numero, public.fecha_utc_inmutable(hora_llegada));


--
-- Name: idx_turnos_sucursal_dia; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_turnos_sucursal_dia ON public.turnos USING btree (sucursal_id, hora_llegada);


--
-- Name: barberias trg_barberias_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_barberias_actualizado_en BEFORE UPDATE ON public.barberias FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: barberos trg_barberos_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_barberos_actualizado_en BEFORE UPDATE ON public.barberos FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: citas trg_citas_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_citas_actualizado_en BEFORE UPDATE ON public.citas FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: configuraciones_barberia trg_configuraciones_barberia_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_configuraciones_barberia_actualizado_en BEFORE UPDATE ON public.configuraciones_barberia FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: insumos trg_insumos_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_insumos_actualizado_en BEFORE UPDATE ON public.insumos FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: pagos trg_pagos_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_pagos_actualizado_en BEFORE UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: perfiles trg_perfiles_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_perfiles_actualizado_en BEFORE UPDATE ON public.perfiles FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: perfiles trg_perfiles_evitar_escalada_privilegios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_perfiles_evitar_escalada_privilegios BEFORE UPDATE ON public.perfiles FOR EACH ROW EXECUTE FUNCTION public.evitar_escalada_privilegios();


--
-- Name: programas_fidelidad trg_programas_fidelidad_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_programas_fidelidad_actualizado_en BEFORE UPDATE ON public.programas_fidelidad FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: promociones trg_promociones_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_promociones_actualizado_en BEFORE UPDATE ON public.promociones FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: reportes_insumo trg_reportes_insumo_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_reportes_insumo_actualizado_en BEFORE UPDATE ON public.reportes_insumo FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: servicios trg_servicios_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_servicios_actualizado_en BEFORE UPDATE ON public.servicios FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: sucursales trg_sucursales_actualizado_en; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sucursales_actualizado_en BEFORE UPDATE ON public.sucursales FOR EACH ROW EXECUTE FUNCTION public.actualizar_columna_actualizado_en();


--
-- Name: accesos_admin_uso accesos_admin_uso_perfil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accesos_admin_uso
    ADD CONSTRAINT accesos_admin_uso_perfil_id_fkey FOREIGN KEY (perfil_id) REFERENCES public.perfiles(id) ON DELETE CASCADE;


--
-- Name: barberos barberos_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barberos
    ADD CONSTRAINT barberos_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: barberos barberos_perfil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barberos
    ADD CONSTRAINT barberos_perfil_id_fkey FOREIGN KEY (perfil_id) REFERENCES public.perfiles(id) ON DELETE CASCADE;


--
-- Name: barberos barberos_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barberos
    ADD CONSTRAINT barberos_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id) ON DELETE CASCADE;


--
-- Name: citas citas_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: citas citas_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE CASCADE;


--
-- Name: citas citas_cancelado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_cancelado_por_fkey FOREIGN KEY (cancelado_por) REFERENCES public.perfiles(id);


--
-- Name: citas citas_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.perfiles(id) ON DELETE CASCADE;


--
-- Name: citas citas_cliente_walkin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_cliente_walkin_id_fkey FOREIGN KEY (cliente_walkin_id) REFERENCES public.clientes_walkin(id) ON DELETE SET NULL;


--
-- Name: citas citas_completado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_completado_por_fkey FOREIGN KEY (completado_por) REFERENCES public.perfiles(id);


--
-- Name: citas citas_promocion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_promocion_id_fkey FOREIGN KEY (promocion_id) REFERENCES public.promociones(id) ON DELETE SET NULL;


--
-- Name: citas citas_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicios(id) ON DELETE RESTRICT;


--
-- Name: citas citas_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id) ON DELETE CASCADE;


--
-- Name: clientes_walkin clientes_walkin_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes_walkin
    ADD CONSTRAINT clientes_walkin_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: configuraciones_barberia configuraciones_barberia_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuraciones_barberia
    ADD CONSTRAINT configuraciones_barberia_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: horarios_barbero horarios_barbero_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horarios_barbero
    ADD CONSTRAINT horarios_barbero_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: horarios_barbero horarios_barbero_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horarios_barbero
    ADD CONSTRAINT horarios_barbero_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE CASCADE;


--
-- Name: insignias_ranking_barberos insignias_ranking_barberos_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insignias_ranking_barberos
    ADD CONSTRAINT insignias_ranking_barberos_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE CASCADE;


--
-- Name: insignias_ranking_barberos insignias_ranking_barberos_programa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insignias_ranking_barberos
    ADD CONSTRAINT insignias_ranking_barberos_programa_id_fkey FOREIGN KEY (programa_id) REFERENCES public.programas_ranking_barberos(id) ON DELETE CASCADE;


--
-- Name: insumos insumos_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: insumos_barbero insumos_barbero_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos_barbero
    ADD CONSTRAINT insumos_barbero_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: insumos_barbero insumos_barbero_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos_barbero
    ADD CONSTRAINT insumos_barbero_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE CASCADE;


--
-- Name: insumos_barbero insumos_barbero_insumo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos_barbero
    ADD CONSTRAINT insumos_barbero_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES public.insumos(id) ON DELETE CASCADE;


--
-- Name: insumos insumos_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id) ON DELETE CASCADE;


--
-- Name: pagos pagos_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: pagos pagos_cita_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_cita_id_fkey FOREIGN KEY (cita_id) REFERENCES public.citas(id) ON DELETE CASCADE;


--
-- Name: pagos pagos_verificado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_verificado_por_fkey FOREIGN KEY (verificado_por) REFERENCES public.perfiles(id) ON DELETE SET NULL;


--
-- Name: perfiles perfiles_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfiles
    ADD CONSTRAINT perfiles_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE SET NULL;


--
-- Name: perfiles perfiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfiles
    ADD CONSTRAINT perfiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: perfiles perfiles_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfiles
    ADD CONSTRAINT perfiles_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id) ON DELETE SET NULL;


--
-- Name: programas_fidelidad programas_fidelidad_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_fidelidad
    ADD CONSTRAINT programas_fidelidad_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: programas_ranking_barberos programas_ranking_barberos_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_ranking_barberos
    ADD CONSTRAINT programas_ranking_barberos_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: programas_ranking_barberos programas_ranking_barberos_barbero_ganador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_ranking_barberos
    ADD CONSTRAINT programas_ranking_barberos_barbero_ganador_id_fkey FOREIGN KEY (barbero_ganador_id) REFERENCES public.barberos(id);


--
-- Name: programas_ranking_barberos programas_ranking_barberos_cerrado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_ranking_barberos
    ADD CONSTRAINT programas_ranking_barberos_cerrado_por_fkey FOREIGN KEY (cerrado_por) REFERENCES public.perfiles(id);


--
-- Name: programas_ranking_barberos programas_ranking_barberos_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programas_ranking_barberos
    ADD CONSTRAINT programas_ranking_barberos_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id) ON DELETE CASCADE;


--
-- Name: promociones promociones_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promociones
    ADD CONSTRAINT promociones_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: promociones promociones_cliente_exclusivo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promociones
    ADD CONSTRAINT promociones_cliente_exclusivo_id_fkey FOREIGN KEY (cliente_exclusivo_id) REFERENCES public.perfiles(id) ON DELETE CASCADE;


--
-- Name: promociones promociones_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promociones
    ADD CONSTRAINT promociones_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicios(id) ON DELETE SET NULL;


--
-- Name: reclamaciones_fidelidad reclamaciones_fidelidad_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reclamaciones_fidelidad
    ADD CONSTRAINT reclamaciones_fidelidad_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.perfiles(id) ON DELETE CASCADE;


--
-- Name: reclamaciones_fidelidad reclamaciones_fidelidad_programa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reclamaciones_fidelidad
    ADD CONSTRAINT reclamaciones_fidelidad_programa_id_fkey FOREIGN KEY (programa_id) REFERENCES public.programas_fidelidad(id) ON DELETE CASCADE;


--
-- Name: reclamaciones_fidelidad reclamaciones_fidelidad_promocion_generada_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reclamaciones_fidelidad
    ADD CONSTRAINT reclamaciones_fidelidad_promocion_generada_id_fkey FOREIGN KEY (promocion_generada_id) REFERENCES public.promociones(id) ON DELETE CASCADE;


--
-- Name: reportes_insumo reportes_insumo_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes_insumo
    ADD CONSTRAINT reportes_insumo_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: reportes_insumo reportes_insumo_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes_insumo
    ADD CONSTRAINT reportes_insumo_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE CASCADE;


--
-- Name: reportes_insumo reportes_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes_insumo
    ADD CONSTRAINT reportes_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES public.insumos(id) ON DELETE CASCADE;


--
-- Name: reportes_insumo reportes_insumo_revisado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes_insumo
    ADD CONSTRAINT reportes_insumo_revisado_por_fkey FOREIGN KEY (revisado_por) REFERENCES public.perfiles(id) ON DELETE SET NULL;


--
-- Name: resenas resenas_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resenas
    ADD CONSTRAINT resenas_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: resenas resenas_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resenas
    ADD CONSTRAINT resenas_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE CASCADE;


--
-- Name: resenas resenas_cita_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resenas
    ADD CONSTRAINT resenas_cita_id_fkey FOREIGN KEY (cita_id) REFERENCES public.citas(id) ON DELETE CASCADE;


--
-- Name: resenas resenas_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resenas
    ADD CONSTRAINT resenas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.perfiles(id) ON DELETE CASCADE;


--
-- Name: servicios servicios_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: sucursales sucursales_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sucursales
    ADD CONSTRAINT sucursales_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: turnos turnos_barberia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_barberia_id_fkey FOREIGN KEY (barberia_id) REFERENCES public.barberias(id) ON DELETE CASCADE;


--
-- Name: turnos turnos_barbero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_barbero_id_fkey FOREIGN KEY (barbero_id) REFERENCES public.barberos(id) ON DELETE SET NULL;


--
-- Name: turnos turnos_cita_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_cita_id_fkey FOREIGN KEY (cita_id) REFERENCES public.citas(id) ON DELETE SET NULL;


--
-- Name: turnos turnos_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.perfiles(id) ON DELETE SET NULL;


--
-- Name: turnos turnos_cliente_walkin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_cliente_walkin_id_fkey FOREIGN KEY (cliente_walkin_id) REFERENCES public.clientes_walkin(id) ON DELETE SET NULL;


--
-- Name: turnos turnos_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicios(id) ON DELETE RESTRICT;


--
-- Name: turnos turnos_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id) ON DELETE CASCADE;


--
-- Name: accesos_admin_uso; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.accesos_admin_uso ENABLE ROW LEVEL SECURITY;

--
-- Name: accesos_admin_uso accesos_admin_uso_insert_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY accesos_admin_uso_insert_policy ON public.accesos_admin_uso FOR INSERT WITH CHECK ((perfil_id = auth.uid()));


--
-- Name: accesos_admin_uso accesos_admin_uso_select_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY accesos_admin_uso_select_policy ON public.accesos_admin_uso FOR SELECT USING ((perfil_id = auth.uid()));


--
-- Name: barberias; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.barberias ENABLE ROW LEVEL SECURITY;

--
-- Name: barberias barberias_insert_superadmin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY barberias_insert_superadmin ON public.barberias FOR INSERT WITH CHECK (public.es_superadmin());


--
-- Name: barberias barberias_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY barberias_select ON public.barberias FOR SELECT USING ((public.es_superadmin() OR (id = public.obtener_barberia_id_actual()) OR (activo = true)));


--
-- Name: barberias barberias_update_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY barberias_update_admin ON public.barberias FOR UPDATE USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (id = public.obtener_barberia_id_actual()))));


--
-- Name: barberos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.barberos ENABLE ROW LEVEL SECURITY;

--
-- Name: barberos barberos_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY barberos_escritura_admin ON public.barberos USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: barberos barberos_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY barberos_select ON public.barberos FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: citas; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.citas ENABLE ROW LEVEL SECURITY;

--
-- Name: citas citas_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY citas_insert ON public.citas FOR INSERT WITH CHECK (((barberia_id = public.obtener_barberia_id_actual()) AND ((cliente_id = auth.uid()) OR public.es_admin_o_superior() OR public.es_barbero_propietario(barbero_id))));


--
-- Name: citas citas_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY citas_select ON public.citas FOR SELECT USING ((public.es_superadmin() OR (cliente_id = auth.uid()) OR public.es_barbero_propietario(barbero_id) OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())) OR ((public.obtener_rol_actual() = 'secretaria'::public.rol_usuario) AND (sucursal_id = public.obtener_sucursal_id_actual()))));


--
-- Name: citas citas_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY citas_update ON public.citas FOR UPDATE USING ((public.es_superadmin() OR (cliente_id = auth.uid()) OR public.es_barbero_propietario(barbero_id) OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: clientes_walkin; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clientes_walkin ENABLE ROW LEVEL SECURITY;

--
-- Name: clientes_walkin clientes_walkin_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY clientes_walkin_insert ON public.clientes_walkin FOR INSERT WITH CHECK ((public.es_superadmin() OR ((barberia_id = public.obtener_barberia_id_actual()) AND public.es_admin_o_superior_o_secretaria())));


--
-- Name: clientes_walkin clientes_walkin_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY clientes_walkin_select ON public.clientes_walkin FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: configuraciones_barberia; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.configuraciones_barberia ENABLE ROW LEVEL SECURITY;

--
-- Name: configuraciones_barberia configuraciones_barberia_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY configuraciones_barberia_escritura_admin ON public.configuraciones_barberia USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: configuraciones_barberia configuraciones_barberia_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY configuraciones_barberia_select ON public.configuraciones_barberia FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: horarios_barbero; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.horarios_barbero ENABLE ROW LEVEL SECURITY;

--
-- Name: horarios_barbero horarios_barbero_escritura; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY horarios_barbero_escritura ON public.horarios_barbero USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())) OR public.es_barbero_propietario(barbero_id))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())) OR public.es_barbero_propietario(barbero_id)));


--
-- Name: horarios_barbero horarios_barbero_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY horarios_barbero_select ON public.horarios_barbero FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: insignias_ranking_barberos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.insignias_ranking_barberos ENABLE ROW LEVEL SECURITY;

--
-- Name: insignias_ranking_barberos insignias_ranking_barberos_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY insignias_ranking_barberos_select ON public.insignias_ranking_barberos FOR SELECT USING ((public.es_barbero_propietario(barbero_id) OR (EXISTS ( SELECT 1
   FROM public.programas_ranking_barberos p
  WHERE ((p.id = insignias_ranking_barberos.programa_id) AND (p.barberia_id = public.obtener_barberia_id_actual()) AND public.es_admin_o_superior())))));


--
-- Name: insumos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.insumos ENABLE ROW LEVEL SECURITY;

--
-- Name: insumos_barbero; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.insumos_barbero ENABLE ROW LEVEL SECURITY;

--
-- Name: insumos_barbero insumos_barbero_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY insumos_barbero_escritura_admin ON public.insumos_barbero USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: insumos_barbero insumos_barbero_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY insumos_barbero_select ON public.insumos_barbero FOR SELECT USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())) OR public.es_barbero_propietario(barbero_id)));


--
-- Name: insumos insumos_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY insumos_escritura_admin ON public.insumos USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: insumos insumos_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY insumos_select ON public.insumos FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: pagos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pagos ENABLE ROW LEVEL SECURITY;

--
-- Name: pagos pagos_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY pagos_insert ON public.pagos FOR INSERT WITH CHECK (((barberia_id = public.obtener_barberia_id_actual()) AND (EXISTS ( SELECT 1
   FROM public.citas c
  WHERE ((c.id = pagos.cita_id) AND ((c.cliente_id = auth.uid()) OR public.es_admin_o_superior()))))));


--
-- Name: pagos pagos_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY pagos_select ON public.pagos FOR SELECT USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())) OR (EXISTS ( SELECT 1
   FROM public.citas c
  WHERE ((c.id = pagos.cita_id) AND (c.cliente_id = auth.uid()))))));


--
-- Name: pagos pagos_update_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY pagos_update_admin ON public.pagos FOR UPDATE USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: perfiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

--
-- Name: perfiles perfiles_insert_propio; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY perfiles_insert_propio ON public.perfiles FOR INSERT WITH CHECK ((id = auth.uid()));


--
-- Name: perfiles perfiles_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY perfiles_select ON public.perfiles FOR SELECT USING (((id = auth.uid()) OR public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: perfiles perfiles_select_clientes_de_mis_citas; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY perfiles_select_clientes_de_mis_citas ON public.perfiles FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.citas c
  WHERE ((c.cliente_id = perfiles.id) AND (c.barberia_id = public.obtener_barberia_id_actual()) AND public.es_barbero_propietario(c.barbero_id)))));


--
-- Name: perfiles perfiles_update_propio; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY perfiles_update_propio ON public.perfiles FOR UPDATE USING (((id = auth.uid()) OR public.es_superadmin())) WITH CHECK (((id = auth.uid()) OR public.es_superadmin()));


--
-- Name: programas_fidelidad; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.programas_fidelidad ENABLE ROW LEVEL SECURITY;

--
-- Name: programas_fidelidad programas_fidelidad_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_fidelidad_delete ON public.programas_fidelidad FOR DELETE USING ((public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: programas_fidelidad programas_fidelidad_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_fidelidad_insert ON public.programas_fidelidad FOR INSERT WITH CHECK ((public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: programas_fidelidad programas_fidelidad_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_fidelidad_select ON public.programas_fidelidad FOR SELECT USING (((barberia_id = public.obtener_barberia_id_actual()) AND (public.es_admin_o_superior() OR (activo = true))));


--
-- Name: programas_fidelidad programas_fidelidad_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_fidelidad_update ON public.programas_fidelidad FOR UPDATE USING ((public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: programas_ranking_barberos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.programas_ranking_barberos ENABLE ROW LEVEL SECURITY;

--
-- Name: programas_ranking_barberos programas_ranking_barberos_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_ranking_barberos_insert ON public.programas_ranking_barberos FOR INSERT WITH CHECK ((public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: programas_ranking_barberos programas_ranking_barberos_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_ranking_barberos_select ON public.programas_ranking_barberos FOR SELECT USING (((barberia_id = public.obtener_barberia_id_actual()) AND (public.es_admin_o_superior() OR (EXISTS ( SELECT 1
   FROM public.barberos b
  WHERE ((b.perfil_id = auth.uid()) AND (b.sucursal_id = programas_ranking_barberos.sucursal_id)))))));


--
-- Name: programas_ranking_barberos programas_ranking_barberos_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY programas_ranking_barberos_update ON public.programas_ranking_barberos FOR UPDATE USING ((public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: promociones; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.promociones ENABLE ROW LEVEL SECURITY;

--
-- Name: promociones promociones_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY promociones_escritura_admin ON public.promociones USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: promociones promociones_select_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY promociones_select_policy ON public.promociones FOR SELECT USING (((barberia_id = public.obtener_barberia_id_actual()) AND (public.es_admin_o_superior() OR ((activo = true) AND (cliente_exclusivo_id IS NULL) AND ((fecha_inicio IS NULL) OR (fecha_inicio <= CURRENT_DATE)) AND ((fecha_fin IS NULL) OR (fecha_fin >= CURRENT_DATE))) OR (cliente_exclusivo_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.citas c
  WHERE ((c.promocion_id = promociones.id) AND (c.cliente_id = auth.uid())))))));


--
-- Name: reclamaciones_fidelidad; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.reclamaciones_fidelidad ENABLE ROW LEVEL SECURITY;

--
-- Name: reclamaciones_fidelidad reclamaciones_fidelidad_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reclamaciones_fidelidad_select ON public.reclamaciones_fidelidad FOR SELECT USING (((cliente_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.programas_fidelidad pf
  WHERE ((pf.id = reclamaciones_fidelidad.programa_id) AND (pf.barberia_id = public.obtener_barberia_id_actual()) AND public.es_admin_o_superior())))));


--
-- Name: reportes_insumo; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.reportes_insumo ENABLE ROW LEVEL SECURITY;

--
-- Name: reportes_insumo reportes_insumo_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reportes_insumo_insert ON public.reportes_insumo FOR INSERT WITH CHECK (((barberia_id = public.obtener_barberia_id_actual()) AND public.es_barbero_propietario(barbero_id)));


--
-- Name: reportes_insumo reportes_insumo_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reportes_insumo_select ON public.reportes_insumo FOR SELECT USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())) OR public.es_barbero_propietario(barbero_id)));


--
-- Name: reportes_insumo reportes_insumo_update_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reportes_insumo_update_admin ON public.reportes_insumo FOR UPDATE USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: resenas; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.resenas ENABLE ROW LEVEL SECURITY;

--
-- Name: resenas resenas_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY resenas_select ON public.resenas FOR SELECT USING ((public.es_superadmin() OR (cliente_id = auth.uid()) OR public.es_barbero_propietario(barbero_id) OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: servicios; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;

--
-- Name: servicios servicios_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY servicios_escritura_admin ON public.servicios USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: servicios servicios_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY servicios_select ON public.servicios FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: sucursales; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.sucursales ENABLE ROW LEVEL SECURITY;

--
-- Name: sucursales sucursales_escritura_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sucursales_escritura_admin ON public.sucursales USING ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual())))) WITH CHECK ((public.es_superadmin() OR (public.es_admin_o_superior() AND (barberia_id = public.obtener_barberia_id_actual()))));


--
-- Name: sucursales sucursales_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sucursales_select ON public.sucursales FOR SELECT USING ((public.es_superadmin() OR (barberia_id = public.obtener_barberia_id_actual())));


--
-- Name: turnos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.turnos ENABLE ROW LEVEL SECURITY;

--
-- Name: turnos turnos_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY turnos_insert ON public.turnos FOR INSERT WITH CHECK ((public.es_superadmin() OR ((barberia_id = public.obtener_barberia_id_actual()) AND (public.es_admin_o_superior() OR (sucursal_id = public.obtener_sucursal_id_actual())))));


--
-- Name: turnos turnos_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY turnos_select ON public.turnos FOR SELECT USING ((public.es_superadmin() OR ((barberia_id = public.obtener_barberia_id_actual()) AND (public.es_admin_o_superior() OR (sucursal_id = public.obtener_sucursal_id_actual())))));


--
-- Name: turnos turnos_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY turnos_update ON public.turnos FOR UPDATE USING ((public.es_superadmin() OR ((barberia_id = public.obtener_barberia_id_actual()) AND (public.es_admin_o_superior() OR (sucursal_id = public.obtener_sucursal_id_actual())))));


--
-- Name: versiones_app; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.versiones_app ENABLE ROW LEVEL SECURITY;

--
-- Name: versiones_app versiones_app_escritura_superadmin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY versiones_app_escritura_superadmin ON public.versiones_app USING (public.es_superadmin()) WITH CHECK (public.es_superadmin());


--
-- Name: versiones_app versiones_app_select_publico; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY versiones_app_select_publico ON public.versiones_app FOR SELECT USING (true);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT USAGE ON SCHEMA public TO lector_reportes_powerbi;


--
-- Name: FUNCTION actualizar_columna_actualizado_en(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.actualizar_columna_actualizado_en() TO anon;
GRANT ALL ON FUNCTION public.actualizar_columna_actualizado_en() TO authenticated;
GRANT ALL ON FUNCTION public.actualizar_columna_actualizado_en() TO service_role;


--
-- Name: TABLE insumos_barbero; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.insumos_barbero TO anon;
GRANT ALL ON TABLE public.insumos_barbero TO authenticated;
GRANT ALL ON TABLE public.insumos_barbero TO service_role;


--
-- Name: FUNCTION asignar_insumo_barbero(p_insumo_id uuid, p_barbero_id uuid, p_cantidad integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.asignar_insumo_barbero(p_insumo_id uuid, p_barbero_id uuid, p_cantidad integer) TO anon;
GRANT ALL ON FUNCTION public.asignar_insumo_barbero(p_insumo_id uuid, p_barbero_id uuid, p_cantidad integer) TO authenticated;
GRANT ALL ON FUNCTION public.asignar_insumo_barbero(p_insumo_id uuid, p_barbero_id uuid, p_cantidad integer) TO service_role;


--
-- Name: FUNCTION buscar_cliente_por_email(p_email text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.buscar_cliente_por_email(p_email text) TO anon;
GRANT ALL ON FUNCTION public.buscar_cliente_por_email(p_email text) TO authenticated;
GRANT ALL ON FUNCTION public.buscar_cliente_por_email(p_email text) TO service_role;


--
-- Name: FUNCTION calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid) TO anon;
GRANT ALL ON FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid) TO service_role;


--
-- Name: FUNCTION calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid, p_promocion_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid, p_promocion_id uuid) TO anon;
GRANT ALL ON FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid, p_promocion_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.calcular_huecos_libres_hoy(p_sucursal_id uuid, p_duracion_min integer, p_barbero_id uuid, p_promocion_id uuid) TO service_role;


--
-- Name: TABLE resenas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.resenas TO anon;
GRANT ALL ON TABLE public.resenas TO authenticated;
GRANT ALL ON TABLE public.resenas TO service_role;


--
-- Name: FUNCTION calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) TO anon;
GRANT ALL ON FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) TO authenticated;
GRANT ALL ON FUNCTION public.calificar_cita(p_cita_id uuid, p_calificacion integer, p_comentario text) TO service_role;


--
-- Name: TABLE citas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.citas TO anon;
GRANT ALL ON TABLE public.citas TO authenticated;
GRANT ALL ON TABLE public.citas TO service_role;


--
-- Name: FUNCTION cancelar_cita_cliente(p_cita_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) TO anon;
GRANT ALL ON FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancelar_cita_cliente(p_cita_id uuid) TO service_role;


--
-- Name: FUNCTION cancelar_citas_pago_vencido(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.cancelar_citas_pago_vencido() TO anon;
GRANT ALL ON FUNCTION public.cancelar_citas_pago_vencido() TO authenticated;
GRANT ALL ON FUNCTION public.cancelar_citas_pago_vencido() TO service_role;


--
-- Name: TABLE turnos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.turnos TO anon;
GRANT ALL ON TABLE public.turnos TO authenticated;
GRANT ALL ON TABLE public.turnos TO service_role;


--
-- Name: FUNCTION cancelar_turno(p_turno_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.cancelar_turno(p_turno_id uuid) TO anon;
GRANT ALL ON FUNCTION public.cancelar_turno(p_turno_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancelar_turno(p_turno_id uuid) TO service_role;


--
-- Name: TABLE programas_ranking_barberos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.programas_ranking_barberos TO anon;
GRANT ALL ON TABLE public.programas_ranking_barberos TO authenticated;
GRANT ALL ON TABLE public.programas_ranking_barberos TO service_role;


--
-- Name: FUNCTION cerrar_programa_ranking(p_programa_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) TO anon;
GRANT ALL ON FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cerrar_programa_ranking(p_programa_id uuid) TO service_role;


--
-- Name: FUNCTION completar_turno_y_cobrar(p_turno_id uuid, p_monto numeric, p_metodo public.metodo_pago); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.completar_turno_y_cobrar(p_turno_id uuid, p_monto numeric, p_metodo public.metodo_pago) TO anon;
GRANT ALL ON FUNCTION public.completar_turno_y_cobrar(p_turno_id uuid, p_monto numeric, p_metodo public.metodo_pago) TO authenticated;
GRANT ALL ON FUNCTION public.completar_turno_y_cobrar(p_turno_id uuid, p_monto numeric, p_metodo public.metodo_pago) TO service_role;


--
-- Name: FUNCTION confirmar_llegada_cita(p_cita_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) TO anon;
GRANT ALL ON FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.confirmar_llegada_cita(p_cita_id uuid) TO service_role;


--
-- Name: TABLE pagos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pagos TO anon;
GRANT ALL ON TABLE public.pagos TO authenticated;
GRANT ALL ON TABLE public.pagos TO service_role;


--
-- Name: FUNCTION confirmar_pago(p_pago_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.confirmar_pago(p_pago_id uuid) TO anon;
GRANT ALL ON FUNCTION public.confirmar_pago(p_pago_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.confirmar_pago(p_pago_id uuid) TO service_role;


--
-- Name: FUNCTION crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) TO anon;
GRANT ALL ON FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) TO authenticated;
GRANT ALL ON FUNCTION public.crear_turno(p_sucursal_id uuid, p_servicio_id uuid, p_cliente_id uuid, p_cliente_walkin_id uuid, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) TO service_role;


--
-- Name: FUNCTION crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) TO anon;
GRANT ALL ON FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) TO authenticated;
GRANT ALL ON FUNCTION public.crear_turno_walkin(p_sucursal_id uuid, p_servicio_id uuid, p_nombre text, p_telefono text, p_monto_precobrado numeric, p_metodo_precobrado public.metodo_pago) TO service_role;


--
-- Name: FUNCTION es_admin_o_superior(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.es_admin_o_superior() TO anon;
GRANT ALL ON FUNCTION public.es_admin_o_superior() TO authenticated;
GRANT ALL ON FUNCTION public.es_admin_o_superior() TO service_role;


--
-- Name: FUNCTION es_admin_o_superior_o_secretaria(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.es_admin_o_superior_o_secretaria() TO anon;
GRANT ALL ON FUNCTION public.es_admin_o_superior_o_secretaria() TO authenticated;
GRANT ALL ON FUNCTION public.es_admin_o_superior_o_secretaria() TO service_role;


--
-- Name: FUNCTION es_barbero_propietario(id_barbero uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.es_barbero_propietario(id_barbero uuid) TO anon;
GRANT ALL ON FUNCTION public.es_barbero_propietario(id_barbero uuid) TO authenticated;
GRANT ALL ON FUNCTION public.es_barbero_propietario(id_barbero uuid) TO service_role;


--
-- Name: FUNCTION es_cliente_o_superior(p_barberia_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) TO anon;
GRANT ALL ON FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.es_cliente_o_superior(p_barberia_id uuid) TO service_role;


--
-- Name: FUNCTION es_superadmin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.es_superadmin() TO anon;
GRANT ALL ON FUNCTION public.es_superadmin() TO authenticated;
GRANT ALL ON FUNCTION public.es_superadmin() TO service_role;


--
-- Name: FUNCTION evitar_escalada_privilegios(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.evitar_escalada_privilegios() TO anon;
GRANT ALL ON FUNCTION public.evitar_escalada_privilegios() TO authenticated;
GRANT ALL ON FUNCTION public.evitar_escalada_privilegios() TO service_role;


--
-- Name: FUNCTION fecha_utc_inmutable(marca timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) TO service_role;


--
-- Name: FUNCTION guardar_marca_barberia(p_nombre text, p_slogan text, p_url_logo text, p_color_acento_hex text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.guardar_marca_barberia(p_nombre text, p_slogan text, p_url_logo text, p_color_acento_hex text) TO anon;
GRANT ALL ON FUNCTION public.guardar_marca_barberia(p_nombre text, p_slogan text, p_url_logo text, p_color_acento_hex text) TO authenticated;
GRANT ALL ON FUNCTION public.guardar_marca_barberia(p_nombre text, p_slogan text, p_url_logo text, p_color_acento_hex text) TO service_role;


--
-- Name: FUNCTION guardar_perfil_barbero(p_descripcion text, p_especialidades text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.guardar_perfil_barbero(p_descripcion text, p_especialidades text[]) TO anon;
GRANT ALL ON FUNCTION public.guardar_perfil_barbero(p_descripcion text, p_especialidades text[]) TO authenticated;
GRANT ALL ON FUNCTION public.guardar_perfil_barbero(p_descripcion text, p_especialidades text[]) TO service_role;


--
-- Name: FUNCTION invitar_barbero_por_email(email_barbero text, id_sucursal uuid, especialidades text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.invitar_barbero_por_email(email_barbero text, id_sucursal uuid, especialidades text[]) TO anon;
GRANT ALL ON FUNCTION public.invitar_barbero_por_email(email_barbero text, id_sucursal uuid, especialidades text[]) TO authenticated;
GRANT ALL ON FUNCTION public.invitar_barbero_por_email(email_barbero text, id_sucursal uuid, especialidades text[]) TO service_role;


--
-- Name: FUNCTION invitar_secretaria_por_email(email_secretaria text, id_sucursal uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.invitar_secretaria_por_email(email_secretaria text, id_sucursal uuid) TO anon;
GRANT ALL ON FUNCTION public.invitar_secretaria_por_email(email_secretaria text, id_sucursal uuid) TO authenticated;
GRANT ALL ON FUNCTION public.invitar_secretaria_por_email(email_secretaria text, id_sucursal uuid) TO service_role;


--
-- Name: FUNCTION llamar_turno(p_turno_id uuid, p_barbero_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) TO anon;
GRANT ALL ON FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.llamar_turno(p_turno_id uuid, p_barbero_id uuid) TO service_role;


--
-- Name: FUNCTION manejar_nuevo_usuario(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.manejar_nuevo_usuario() TO anon;
GRANT ALL ON FUNCTION public.manejar_nuevo_usuario() TO authenticated;
GRANT ALL ON FUNCTION public.manejar_nuevo_usuario() TO service_role;


--
-- Name: FUNCTION marcar_cita_no_asistio(p_cita_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) TO anon;
GRANT ALL ON FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.marcar_cita_no_asistio(p_cita_id uuid) TO service_role;


--
-- Name: FUNCTION marcar_no_asistio_vencidas(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.marcar_no_asistio_vencidas() TO anon;
GRANT ALL ON FUNCTION public.marcar_no_asistio_vencidas() TO authenticated;
GRANT ALL ON FUNCTION public.marcar_no_asistio_vencidas() TO service_role;


--
-- Name: FUNCTION marcar_premio_entregado(p_programa_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.marcar_premio_entregado(p_programa_id uuid) TO anon;
GRANT ALL ON FUNCTION public.marcar_premio_entregado(p_programa_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.marcar_premio_entregado(p_programa_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_accesos_rapidos_top(p_limite integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_accesos_rapidos_top(p_limite integer) TO anon;
GRANT ALL ON FUNCTION public.obtener_accesos_rapidos_top(p_limite integer) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_accesos_rapidos_top(p_limite integer) TO service_role;


--
-- Name: FUNCTION obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_actividad_por_usuario(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_barberia_id_actual(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_barberia_id_actual() TO anon;
GRANT ALL ON FUNCTION public.obtener_barberia_id_actual() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_barberia_id_actual() TO service_role;


--
-- Name: FUNCTION obtener_barberia_unica_reportes_powerbi(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_barberia_unica_reportes_powerbi() TO anon;
GRANT ALL ON FUNCTION public.obtener_barberia_unica_reportes_powerbi() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_barberia_unica_reportes_powerbi() TO service_role;


--
-- Name: FUNCTION obtener_barberos_publicos(p_sucursal_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_barberos_publicos(p_sucursal_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_barberos_publicos(p_sucursal_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_barberos_publicos(p_sucursal_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_citas_atendidas_dia(p_fecha date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) TO anon;
GRANT ALL ON FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_citas_atendidas_dia(p_fecha date) TO service_role;


--
-- Name: FUNCTION obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_citas_sin_pago_completo(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_clientes_nuevos_dia(p_fecha date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) TO anon;
GRANT ALL ON FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_clientes_nuevos_dia(p_fecha date) TO service_role;


--
-- Name: FUNCTION obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_grilla_horarios(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_horarios_disponibles(p_sucursal_id uuid, p_servicio_id uuid, p_fecha date, p_barbero_id uuid, p_promocion_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_ingresos_por_metodo_pago(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_mis_resenas(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_mis_resenas() TO anon;
GRANT ALL ON FUNCTION public.obtener_mis_resenas() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_mis_resenas() TO service_role;


--
-- Name: FUNCTION obtener_progreso_fidelidad_cliente(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_progreso_fidelidad_cliente() TO anon;
GRANT ALL ON FUNCTION public.obtener_progreso_fidelidad_cliente() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_progreso_fidelidad_cliente() TO service_role;


--
-- Name: FUNCTION obtener_ranking_barberos(p_programa_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_ranking_barberos(p_programa_id uuid) TO service_role;


--
-- Name: FUNCTION obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_reporte_clientes_frecuentes(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_reporte_ingresos_detallado(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_reporte_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_reporte_por_servicio(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_reporte_por_servicio(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_reporte_por_servicio(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_reporte_por_servicio(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_resumen_ingresos(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_resumen_ingresos() TO anon;
GRANT ALL ON FUNCTION public.obtener_resumen_ingresos() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_resumen_ingresos() TO service_role;


--
-- Name: FUNCTION obtener_resumen_ingresos_barbero(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_resumen_ingresos_barbero() TO anon;
GRANT ALL ON FUNCTION public.obtener_resumen_ingresos_barbero() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_resumen_ingresos_barbero() TO service_role;


--
-- Name: FUNCTION obtener_rol_actual(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_rol_actual() TO anon;
GRANT ALL ON FUNCTION public.obtener_rol_actual() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_rol_actual() TO service_role;


--
-- Name: FUNCTION obtener_sucursal_id_actual(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_sucursal_id_actual() TO anon;
GRANT ALL ON FUNCTION public.obtener_sucursal_id_actual() TO authenticated;
GRANT ALL ON FUNCTION public.obtener_sucursal_id_actual() TO service_role;


--
-- Name: FUNCTION obtener_tasa_ausentismo_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_tasa_ausentismo_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.obtener_tasa_ausentismo_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_tasa_ausentismo_por_barbero(p_fecha_inicio timestamp with time zone, p_fecha_fin timestamp with time zone) TO service_role;


--
-- Name: FUNCTION obtener_tendencia_ingresos(p_periodo text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_tendencia_ingresos(p_periodo text) TO anon;
GRANT ALL ON FUNCTION public.obtener_tendencia_ingresos(p_periodo text) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_tendencia_ingresos(p_periodo text) TO service_role;


--
-- Name: FUNCTION obtener_usos_promocion_por_cliente(p_promocion_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.obtener_usos_promocion_por_cliente(p_promocion_id uuid) TO anon;
GRANT ALL ON FUNCTION public.obtener_usos_promocion_por_cliente(p_promocion_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.obtener_usos_promocion_por_cliente(p_promocion_id uuid) TO service_role;


--
-- Name: FUNCTION rechazar_pago(p_pago_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.rechazar_pago(p_pago_id uuid) TO anon;
GRANT ALL ON FUNCTION public.rechazar_pago(p_pago_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.rechazar_pago(p_pago_id uuid) TO service_role;


--
-- Name: TABLE promociones; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.promociones TO anon;
GRANT ALL ON TABLE public.promociones TO authenticated;
GRANT ALL ON TABLE public.promociones TO service_role;


--
-- Name: FUNCTION reclamar_premio_fidelidad(p_programa_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.reclamar_premio_fidelidad(p_programa_id uuid) TO anon;
GRANT ALL ON FUNCTION public.reclamar_premio_fidelidad(p_programa_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.reclamar_premio_fidelidad(p_programa_id uuid) TO service_role;


--
-- Name: FUNCTION reemplazar_horarios_barbero(p_barbero_id uuid, p_horarios jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.reemplazar_horarios_barbero(p_barbero_id uuid, p_horarios jsonb) TO anon;
GRANT ALL ON FUNCTION public.reemplazar_horarios_barbero(p_barbero_id uuid, p_horarios jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.reemplazar_horarios_barbero(p_barbero_id uuid, p_horarios jsonb) TO service_role;


--
-- Name: TABLE reportes_insumo; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.reportes_insumo TO anon;
GRANT ALL ON TABLE public.reportes_insumo TO authenticated;
GRANT ALL ON TABLE public.reportes_insumo TO service_role;


--
-- Name: FUNCTION reportar_insumo(p_insumo_id uuid, p_tipo public.tipo_reporte_insumo, p_cantidad integer, p_descripcion text, p_url_foto text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.reportar_insumo(p_insumo_id uuid, p_tipo public.tipo_reporte_insumo, p_cantidad integer, p_descripcion text, p_url_foto text) TO anon;
GRANT ALL ON FUNCTION public.reportar_insumo(p_insumo_id uuid, p_tipo public.tipo_reporte_insumo, p_cantidad integer, p_descripcion text, p_url_foto text) TO authenticated;
GRANT ALL ON FUNCTION public.reportar_insumo(p_insumo_id uuid, p_tipo public.tipo_reporte_insumo, p_cantidad integer, p_descripcion text, p_url_foto text) TO service_role;


--
-- Name: FUNCTION reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_barbero_id uuid, p_fecha_hora timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_barbero_id uuid, p_fecha_hora timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_barbero_id uuid, p_fecha_hora timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_barbero_id uuid, p_fecha_hora timestamp with time zone) TO service_role;


--
-- Name: FUNCTION reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_fecha_hora timestamp with time zone, p_barbero_id uuid, p_promocion_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_fecha_hora timestamp with time zone, p_barbero_id uuid, p_promocion_id uuid) TO anon;
GRANT ALL ON FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_fecha_hora timestamp with time zone, p_barbero_id uuid, p_promocion_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.reservar_cita(p_sucursal_id uuid, p_servicio_id uuid, p_fecha_hora timestamp with time zone, p_barbero_id uuid, p_promocion_id uuid) TO service_role;


--
-- Name: FUNCTION revisar_reporte_insumo(p_reporte_id uuid, p_aprobar boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.revisar_reporte_insumo(p_reporte_id uuid, p_aprobar boolean) TO anon;
GRANT ALL ON FUNCTION public.revisar_reporte_insumo(p_reporte_id uuid, p_aprobar boolean) TO authenticated;
GRANT ALL ON FUNCTION public.revisar_reporte_insumo(p_reporte_id uuid, p_aprobar boolean) TO service_role;


--
-- Name: FUNCTION revocar_secretaria(p_perfil_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.revocar_secretaria(p_perfil_id uuid) TO anon;
GRANT ALL ON FUNCTION public.revocar_secretaria(p_perfil_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.revocar_secretaria(p_perfil_id uuid) TO service_role;


--
-- Name: FUNCTION rls_auto_enable(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.rls_auto_enable() TO anon;
GRANT ALL ON FUNCTION public.rls_auto_enable() TO authenticated;
GRANT ALL ON FUNCTION public.rls_auto_enable() TO service_role;


--
-- Name: FUNCTION subir_comprobante_pago(p_cita_id uuid, p_monto numeric, p_url_comprobante text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.subir_comprobante_pago(p_cita_id uuid, p_monto numeric, p_url_comprobante text) TO anon;
GRANT ALL ON FUNCTION public.subir_comprobante_pago(p_cita_id uuid, p_monto numeric, p_url_comprobante text) TO authenticated;
GRANT ALL ON FUNCTION public.subir_comprobante_pago(p_cita_id uuid, p_monto numeric, p_url_comprobante text) TO service_role;


--
-- Name: FUNCTION validar_permiso_turno(p_sucursal_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.validar_permiso_turno(p_sucursal_id uuid) TO anon;
GRANT ALL ON FUNCTION public.validar_permiso_turno(p_sucursal_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.validar_permiso_turno(p_sucursal_id uuid) TO service_role;


--
-- Name: TABLE accesos_admin_uso; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.accesos_admin_uso TO anon;
GRANT ALL ON TABLE public.accesos_admin_uso TO authenticated;
GRANT ALL ON TABLE public.accesos_admin_uso TO service_role;


--
-- Name: TABLE barberias; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.barberias TO anon;
GRANT ALL ON TABLE public.barberias TO authenticated;
GRANT ALL ON TABLE public.barberias TO service_role;


--
-- Name: TABLE barberos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.barberos TO anon;
GRANT ALL ON TABLE public.barberos TO authenticated;
GRANT ALL ON TABLE public.barberos TO service_role;


--
-- Name: TABLE clientes_walkin; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.clientes_walkin TO anon;
GRANT ALL ON TABLE public.clientes_walkin TO authenticated;
GRANT ALL ON TABLE public.clientes_walkin TO service_role;


--
-- Name: TABLE configuraciones_barberia; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.configuraciones_barberia TO anon;
GRANT ALL ON TABLE public.configuraciones_barberia TO authenticated;
GRANT ALL ON TABLE public.configuraciones_barberia TO service_role;


--
-- Name: TABLE horarios_barbero; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horarios_barbero TO anon;
GRANT ALL ON TABLE public.horarios_barbero TO authenticated;
GRANT ALL ON TABLE public.horarios_barbero TO service_role;


--
-- Name: TABLE insignias_ranking_barberos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.insignias_ranking_barberos TO anon;
GRANT ALL ON TABLE public.insignias_ranking_barberos TO authenticated;
GRANT ALL ON TABLE public.insignias_ranking_barberos TO service_role;


--
-- Name: TABLE insumos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.insumos TO anon;
GRANT ALL ON TABLE public.insumos TO authenticated;
GRANT ALL ON TABLE public.insumos TO service_role;


--
-- Name: TABLE perfiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.perfiles TO anon;
GRANT ALL ON TABLE public.perfiles TO authenticated;
GRANT ALL ON TABLE public.perfiles TO service_role;


--
-- Name: TABLE programas_fidelidad; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.programas_fidelidad TO anon;
GRANT ALL ON TABLE public.programas_fidelidad TO authenticated;
GRANT ALL ON TABLE public.programas_fidelidad TO service_role;


--
-- Name: TABLE reclamaciones_fidelidad; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.reclamaciones_fidelidad TO anon;
GRANT ALL ON TABLE public.reclamaciones_fidelidad TO authenticated;
GRANT ALL ON TABLE public.reclamaciones_fidelidad TO service_role;


--
-- Name: TABLE servicios; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.servicios TO anon;
GRANT ALL ON TABLE public.servicios TO authenticated;
GRANT ALL ON TABLE public.servicios TO service_role;


--
-- Name: TABLE sucursales; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sucursales TO anon;
GRANT ALL ON TABLE public.sucursales TO authenticated;
GRANT ALL ON TABLE public.sucursales TO service_role;


--
-- Name: TABLE versiones_app; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.versiones_app TO anon;
GRANT ALL ON TABLE public.versiones_app TO authenticated;
GRANT ALL ON TABLE public.versiones_app TO service_role;


--
-- Name: TABLE vista_reportes_barberos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.vista_reportes_barberos TO anon;
GRANT ALL ON TABLE public.vista_reportes_barberos TO authenticated;
GRANT ALL ON TABLE public.vista_reportes_barberos TO service_role;
GRANT SELECT ON TABLE public.vista_reportes_barberos TO lector_reportes_powerbi;


--
-- Name: TABLE vista_reportes_citas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.vista_reportes_citas TO anon;
GRANT ALL ON TABLE public.vista_reportes_citas TO authenticated;
GRANT ALL ON TABLE public.vista_reportes_citas TO service_role;
GRANT SELECT ON TABLE public.vista_reportes_citas TO lector_reportes_powerbi;


--
-- Name: TABLE vista_reportes_servicios; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.vista_reportes_servicios TO anon;
GRANT ALL ON TABLE public.vista_reportes_servicios TO authenticated;
GRANT ALL ON TABLE public.vista_reportes_servicios TO service_role;
GRANT SELECT ON TABLE public.vista_reportes_servicios TO lector_reportes_powerbi;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

\unrestrict RNxmZqS4JSyP1lOqXtX8oZEcLAUTQHnAjvKSGRyuRd7wPGu9wikZAzHxXcQRNYF

