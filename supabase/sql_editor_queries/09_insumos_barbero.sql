--
-- Name: insumos_barbero; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insumos_barbero (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    insumo_id uuid NOT NULL,
    cantidad_asignada integer DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT insumos_barbero_cantidad_asignada_check CHECK ((cantidad_asignada >= 0))
);


ALTER TABLE public.insumos_barbero OWNER TO postgres;
