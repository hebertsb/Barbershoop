--
-- Name: resenas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resenas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    cita_id uuid NOT NULL,
    cliente_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    calificacion integer NOT NULL,
    comentario text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resenas_calificacion_check CHECK (((calificacion >= 1) AND (calificacion <= 5)))
);


ALTER TABLE public.resenas OWNER TO postgres;
