-- ============================================================
-- FIX: Elimina versiones ambiguas de obtener_grilla_horarios
--      y obtener_horarios_disponibles para resolver el error
--      "could not choose the best candidate function"
-- ============================================================
-- El problema: al agregar p_cita_excluir (migración 70) con
-- CREATE OR REPLACE, Postgres crea una NUEVA firma (5 params) sin
-- eliminar la vieja (4 params). Con dos firmas activas, Supabase
-- no puede resolver cuál usar cuando el cliente no manda p_cita_excluir
-- → error "could not choose the best candidate function".
-- Solución: DROP explícito de la firma vieja (4 params).
-- ============================================================

-- 1. Eliminar firma vieja de obtener_grilla_horarios (4 params sin p_cita_excluir)
DROP FUNCTION IF EXISTS public.obtener_grilla_horarios(
  uuid,   -- p_sucursal_id
  uuid,   -- p_servicio_id
  date,   -- p_fecha
  uuid    -- p_barbero_id
);

-- 2. Eliminar firma vieja de obtener_horarios_disponibles (4 params sin p_cita_excluir)
--    (puede que también tenga la versión con solo p_barbero_id sin p_promocion_id)
DROP FUNCTION IF EXISTS public.obtener_horarios_disponibles(
  uuid,   -- p_sucursal_id
  uuid,   -- p_servicio_id
  date,   -- p_fecha
  uuid    -- p_barbero_id
);

-- 3. Verificar las firmas actuales (deben quedar solo las versiones de migración 70)
SELECT
  p.proname AS funcion,
  pg_get_function_arguments(p.oid) AS argumentos
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('obtener_grilla_horarios', 'obtener_horarios_disponibles')
ORDER BY p.proname, p.oid;

-- Resultado esperado después del DROP:
-- obtener_grilla_horarios:      5 params (con p_cita_excluir DEFAULT NULL)
-- obtener_horarios_disponibles: 5 params (con p_cita_excluir DEFAULT NULL)
