--
-- Name: tipo_reporte_insumo; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_reporte_insumo AS ENUM (
    'danado',
    'agotado',
    'perdido'
);


ALTER TYPE public.tipo_reporte_insumo OWNER TO postgres;
