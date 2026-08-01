--
-- Name: turnos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.turnos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    numero integer NOT NULL,
    cliente_id uuid,
    cliente_walkin_id uuid,
    servicio_id uuid NOT NULL,
    barbero_id uuid,
    estado public.estado_turno DEFAULT 'esperando'::public.estado_turno NOT NULL,
    cita_id uuid,
    hora_llegada timestamp with time zone DEFAULT now() NOT NULL,
    hora_atencion timestamp with time zone,
    hora_completado timestamp with time zone,
    monto_precobrado numeric(10,2),
    metodo_precobrado public.metodo_pago,
    CONSTRAINT turnos_check CHECK ((((cliente_id IS NOT NULL) AND (cliente_walkin_id IS NULL)) OR ((cliente_id IS NULL) AND (cliente_walkin_id IS NOT NULL))))
);


ALTER TABLE public.turnos OWNER TO postgres;
