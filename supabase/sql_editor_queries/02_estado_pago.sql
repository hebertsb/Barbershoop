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
