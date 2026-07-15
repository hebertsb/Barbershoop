-- ============================================================================
-- BarberApp - Permitir que invitar_barbero_por_email promueva a 'barbero'
-- sin abrir la puerta general de escalada de privilegios.
-- ============================================================================

-- security definer eleva permisos de tabla pero no cambia lo que auth.uid()
-- resuelve, así que el trigger de 0003 seguía bloqueando la promoción a 'barbero'
-- incluso para un admin ya validado dentro de invitar_barbero_por_email (0004).
--
-- Fix: la función marca una bandera local a su propia transacción
-- (set_config('app.bypass_escalada_privilegios', 'true', true)) justo antes de
-- promover; el trigger solo la respeta cuando el nuevo rol es exactamente
-- 'barbero' (nunca 'admin' ni 'superadmin'), así que aunque la bandera se
-- filtrara no serviría para autopromoverse a admin.
create or replace function evitar_escalada_privilegios()
returns trigger as $$
begin
  if new.rol is distinct from old.rol and not es_superadmin() then
    if not (
      new.rol = 'barbero'
      and coalesce(current_setting('app.bypass_escalada_privilegios', true), 'false') = 'true'
    ) then
      raise exception 'Solo un superadmin puede cambiar el rol.';
    end if;
  end if;

  if new.barberia_id is distinct from old.barberia_id
     and old.barberia_id is not null
     and not es_superadmin() then
    raise exception 'No puedes cambiar de barbería una vez asignada.';
  end if;

  return new;
end;
$$ language plpgsql set search_path = public;
