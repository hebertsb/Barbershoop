--
-- Name: estado_reporte_insumo; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_reporte_insumo AS ENUM (
    'pendiente',
    'atendido',
    'rechazado'
);


ALTER TYPE public.estado_reporte_insumo OWNER TO postgres;
