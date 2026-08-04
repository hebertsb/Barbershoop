-- ============================================================
-- FIX: Elimina versiones ambiguas de obtener_grilla_horarios
--      y obtener_horarios_disponibles para resolver el error
--      "could not choose the best candidate function"
-- ============================================================
-- Situación actual en la BD (4 versiones en total = ambigüedad):
--
--  obtener_grilla_horarios (5 params, SIN p_cita_excluir)   ← VIEJA, DROP
--  obtener_grilla_horarios (6 params, CON p_cita_excluir)   ← NUEVA, conservar
--  obtener_horarios_disponibles (5 params, SIN p_cita_excluir) ← VIEJA, DROP
--  obtener_horarios_disponibles (6 params, CON p_cita_excluir) ← NUEVA, conservar
--
-- Cuando el cliente llama sin p_cita_excluir, Postgres no sabe
-- cuál de las dos firmas elegir → "could not choose the best candidate".
-- ============================================================

-- 1. DROP firma vieja de obtener_grilla_horarios (5 params, sin p_cita_excluir)
DROP FUNCTION IF EXISTS public.obtener_grilla_horarios(
  uuid,         -- p_sucursal_id
  uuid,         -- p_servicio_id
  date,         -- p_fecha
  uuid,         -- p_barbero_id
  uuid          -- p_promocion_id DEFAULT NULL
);

-- 2. DROP firma vieja de obtener_horarios_disponibles (5 params, sin p_cita_excluir)
DROP FUNCTION IF EXISTS public.obtener_horarios_disponibles(
  uuid,         -- p_sucursal_id
  uuid,         -- p_servicio_id
  date,         -- p_fecha
  uuid,         -- p_barbero_id DEFAULT NULL
  uuid          -- p_promocion_id DEFAULT NULL
);

-- 3. Verificar resultado (deben quedar solo las versiones de 6 params)
SELECT
  p.proname AS funcion,
  pg_get_function_arguments(p.oid) AS argumentos
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('obtener_grilla_horarios', 'obtener_horarios_disponibles')
ORDER BY p.proname, p.oid;

-- Resultado esperado (2 filas, una por función):
-- obtener_grilla_horarios:      ...p_promocion_id uuid DEFAULT NULL, p_cita_excluir uuid DEFAULT NULL
-- obtener_horarios_disponibles: ...p_promocion_id uuid DEFAULT NULL, p_cita_excluir uuid DEFAULT NULL
