--
-- Name: citas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.citas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    barbero_id uuid NOT NULL,
    cliente_id uuid,
    servicio_id uuid NOT NULL,
    fecha_hora timestamp with time zone NOT NULL,
    duracion_min integer NOT NULL,
    estado public.estado_cita DEFAULT 'pendiente'::public.estado_cita NOT NULL,
    precio_cobrado numeric(10,2),
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    cliente_walkin_id uuid,
    promocion_id uuid,
    descuento_aplicado numeric(10,2) DEFAULT 0 NOT NULL,
    completado_por uuid,
    cancelado_por uuid,
    CONSTRAINT citas_descuento_aplicado_check CHECK ((descuento_aplicado >= (0)::numeric)),
    CONSTRAINT citas_duracion_min_check CHECK ((duracion_min > 0)),
    CONSTRAINT citas_un_solo_tipo_cliente CHECK ((((cliente_id IS NOT NULL) AND (cliente_walkin_id IS NULL)) OR ((cliente_id IS NULL) AND (cliente_walkin_id IS NOT NULL))))
);


ALTER TABLE public.citas OWNER TO postgres;
