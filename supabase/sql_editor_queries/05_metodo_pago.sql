--
-- Name: metodo_pago; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.metodo_pago AS ENUM (
    'efectivo',
    'qr_manual',
    'pasarela'
);


ALTER TYPE public.metodo_pago OWNER TO postgres;
