--
-- Name: pagos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    cita_id uuid NOT NULL,
    monto numeric(10,2) NOT NULL,
    metodo public.metodo_pago DEFAULT 'qr_manual'::public.metodo_pago NOT NULL,
    estado public.estado_pago DEFAULT 'pendiente'::public.estado_pago NOT NULL,
    url_comprobante text,
    verificado_por uuid,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pagos_monto_check CHECK ((monto >= (0)::numeric))
);


ALTER TABLE public.pagos OWNER TO postgres;
