--
-- Name: rol_usuario; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.rol_usuario AS ENUM (
    'cliente',
    'barbero',
    'admin',
    'superadmin',
    'secretaria'
);


ALTER TYPE public.rol_usuario OWNER TO postgres;
