--
-- Name: fecha_utc_inmutable(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) RETURNS date
    LANGUAGE sql IMMUTABLE
    AS $$
  select (marca at time zone 'utc')::date
$$;


ALTER FUNCTION public.fecha_utc_inmutable(marca timestamp with time zone) OWNER TO postgres;
