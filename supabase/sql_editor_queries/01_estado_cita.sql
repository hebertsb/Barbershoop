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
