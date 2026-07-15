-- ============================================================================
-- BarberApp - Reemplazo atómico de horarios_barbero
-- Evita que un barbero quede sin horarios si el insert falla después del delete.
-- ============================================================================

create or replace function reemplazar_horarios_barbero(
  p_barbero_id uuid,
  p_horarios jsonb
)
returns void as $$
declare
  v_barberia_id uuid;
begin
  select barberia_id into v_barberia_id
  from public.barberos
  where id = p_barbero_id;

  if v_barberia_id is null then
    raise exception 'Barbero no encontrado.';
  end if;

  -- Sin security definer: las políticas RLS de horarios_barbero_escritura
  -- (admin de la barbería o el propio barbero) siguen aplicando al llamador real.
  delete from public.horarios_barbero where barbero_id = p_barbero_id;

  if jsonb_array_length(p_horarios) > 0 then
    insert into public.horarios_barbero (barbero_id, barberia_id, dia_semana, hora_inicio, hora_fin)
    select
      p_barbero_id,
      v_barberia_id,
      (h ->> 'dia_semana')::smallint,
      (h ->> 'hora_inicio')::time,
      (h ->> 'hora_fin')::time
    from jsonb_array_elements(p_horarios) as h;
  end if;
end;
$$ language plpgsql set search_path = public;
