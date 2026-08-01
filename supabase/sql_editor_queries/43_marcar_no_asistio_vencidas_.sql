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
