-- ============================================================================
-- BarberApp - Invitación de barberos por email
-- ============================================================================

create or replace function invitar_barbero_por_email(
  email_barbero text,
  id_sucursal uuid,
  especialidades text[]
)
returns void as $$
declare
  v_barberia_id uuid;
  v_perfil_id uuid;
begin
  -- 1. Validar que el usuario que ejecuta la función es un administrador o superior
  if not es_admin_o_superior() then
    raise exception 'Solo un administrador puede invitar barberos.';
  end if;

  -- 2. Obtener la barbería del administrador
  v_barberia_id := obtener_barberia_id_actual();
  if v_barberia_id is null then
    raise exception 'El administrador no tiene una barbería asignada.';
  end if;

  -- 3. Buscar el perfil del barbero por correo electrónico
  select id into v_perfil_id
  from public.perfiles
  where email = email_barbero;

  if v_perfil_id is null then
    raise exception 'No se encontró ningún usuario registrado con el correo proporcionado.';
  end if;

  -- 4. Validar el tenant del barbero
  -- Si ya tiene barbería y no coincide con la del admin, bloquear (multi-tenant boundary)
  if exists (
    select 1 from public.perfiles
    where id = v_perfil_id and barberia_id is not null and barberia_id != v_barberia_id
  ) then
    raise exception 'El usuario pertenece a otra barbería.';
  end if;

  -- 4b. Validar que la sucursal pertenece a la barbería del admin (sin esto, security
  -- definer bypassa el RLS de sucursales y un admin podría invitar apuntando a una
  -- sucursal ajena).
  if not exists (
    select 1 from public.sucursales
    where id = id_sucursal and barberia_id = v_barberia_id
  ) then
    raise exception 'La sucursal no pertenece a tu barbería.';
  end if;

  -- 5. Promover el rol y asignar barberia_id en perfiles.
  -- security definer eleva los permisos de tabla, pero NO cambia lo que auth.uid()
  -- resuelve, así que el trigger anti-escalada (evitar_escalada_privilegios) igual se
  -- dispara. Le avisamos con esta bandera local a la transacción que este cambio puntual
  -- (promover a 'barbero', ya validado arriba) está autorizado — ver 0005_permitir_invitar_barbero.sql.
  perform set_config('app.bypass_escalada_privilegios', 'true', true);

  update public.perfiles
  set rol = 'barbero',
      barberia_id = v_barberia_id
  where id = v_perfil_id;

  -- 6. Crear el registro en la tabla barberos
  -- Si ya existe para la misma sucursal, solo lo activamos y actualizamos especialidades
  insert into public.barberos (perfil_id, sucursal_id, barberia_id, especialidades, activo)
  values (v_perfil_id, id_sucursal, v_barberia_id, especialidades, true)
  on conflict (perfil_id, sucursal_id) do update
  set especialidades = excluded.especialidades,
      activo = true;

end;
$$ language plpgsql security definer set search_path = public;
