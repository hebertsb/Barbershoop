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
