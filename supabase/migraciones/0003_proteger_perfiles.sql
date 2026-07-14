-- ============================================================================
-- BarberApp - Protección de perfiles: email + anti escalada de privilegios
-- ============================================================================

alter table perfiles add column email text;

-- Reemplaza el trigger de 0001 para copiar también el email.
create or replace function manejar_nuevo_usuario()
returns trigger as $$
begin
  insert into public.perfiles (id, email, nombre, url_foto)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- Nadie cambia su propio rol; nadie cambia su barberia_id una vez asignada.
-- Solo superadmin puede saltarse esto (bootstrap y promoción de admins).
create or replace function evitar_escalada_privilegios()
returns trigger as $$
begin
  if new.rol is distinct from old.rol and not es_superadmin() then
    raise exception 'Solo un superadmin puede cambiar el rol.';
  end if;

  if new.barberia_id is distinct from old.barberia_id
     and old.barberia_id is not null
     and not es_superadmin() then
    raise exception 'No puedes cambiar de barbería una vez asignada.';
  end if;

  return new;
end;
$$ language plpgsql set search_path = public;

create trigger trg_perfiles_evitar_escalada_privilegios
  before update on perfiles
  for each row execute function evitar_escalada_privilegios();
