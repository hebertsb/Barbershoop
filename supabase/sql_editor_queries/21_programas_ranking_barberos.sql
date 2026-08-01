--
-- Name: programas_ranking_barberos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.programas_ranking_barberos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    barberia_id uuid NOT NULL,
    sucursal_id uuid NOT NULL,
    titulo text NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date NOT NULL,
    peso_citas integer DEFAULT 0 NOT NULL,
    peso_ingresos integer DEFAULT 0 NOT NULL,
    peso_clientes integer DEFAULT 0 NOT NULL,
    peso_puntualidad integer DEFAULT 0 NOT NULL,
    tipo_premio text NOT NULL,
    descripcion_premio text NOT NULL,
    estado text DEFAULT 'activo'::text NOT NULL,
    barbero_ganador_id uuid,
    premio_entregado boolean DEFAULT false NOT NULL,
    cerrado_en timestamp with time zone,
    cerrado_por uuid,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    peso_calificacion integer DEFAULT 0 NOT NULL,
    CONSTRAINT fechas_validas CHECK ((fecha_fin >= fecha_inicio)),
    CONSTRAINT pesos_suman_100 CHECK ((((((peso_citas + peso_ingresos) + peso_clientes) + peso_puntualidad) + peso_calificacion) = 100)),
    CONSTRAINT programas_ranking_barberos_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'cerrado'::text]))),
    CONSTRAINT programas_ranking_barberos_peso_calificacion_check CHECK (((peso_calificacion >= 0) AND (peso_calificacion <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_citas_check CHECK (((peso_citas >= 0) AND (peso_citas <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_clientes_check CHECK (((peso_clientes >= 0) AND (peso_clientes <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_ingresos_check CHECK (((peso_ingresos >= 0) AND (peso_ingresos <= 100))),
    CONSTRAINT programas_ranking_barberos_peso_puntualidad_check CHECK (((peso_puntualidad >= 0) AND (peso_puntualidad <= 100))),
    CONSTRAINT programas_ranking_barberos_tipo_premio_check CHECK ((tipo_premio = ANY (ARRAY['dinero'::text, 'insumo'::text, 'sorpresa'::text, 'otro'::text])))
);


ALTER TABLE public.programas_ranking_barberos OWNER TO postgres;
