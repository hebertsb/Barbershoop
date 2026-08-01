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
