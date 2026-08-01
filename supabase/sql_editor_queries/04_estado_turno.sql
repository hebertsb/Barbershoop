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
