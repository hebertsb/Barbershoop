-- ============================================================================
-- BarberApp - Row Level Security multi-tenant
-- Aislamiento estricto por barberia_id. security definer evita recursión
-- infinita al consultar la propia tabla perfiles dentro de las políticas.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Funciones auxiliares (security definer: leen perfiles sin pasar por RLS)
-- ----------------------------------------------------------------------------

create or replace function obtener_barberia_id_actual()
returns uuid as $$
  select barberia_id from public.perfiles where id = auth.uid();
$$ language sql stable security definer set search_path = public;

create or replace function obtener_rol_actual()
returns rol_usuario as $$
  select rol from public.perfiles where id = auth.uid();
$$ language sql stable security definer set search_path = public;

create or replace function es_admin_o_superior()
returns boolean as $$
  select obtener_rol_actual() in ('admin', 'superadmin');
$$ language sql stable security definer set search_path = public;

create or replace function es_superadmin()
returns boolean as $$
  select obtener_rol_actual() = 'superadmin';
$$ language sql stable security definer set search_path = public;

create or replace function es_barbero_propietario(id_barbero uuid)
returns boolean as $$
  select exists (
    select 1 from public.barberos b
    where b.id = id_barbero and b.perfil_id = auth.uid()
  );
$$ language sql stable security definer set search_path = public;

-- ----------------------------------------------------------------------------
-- barberias
-- ----------------------------------------------------------------------------

alter table barberias enable row level security;

create policy barberias_select on barberias
  for select using (
    es_superadmin() or id = obtener_barberia_id_actual() or activo = true
  );

create policy barberias_update_admin on barberias
  for update using (
    es_superadmin() or (es_admin_o_superior() and id = obtener_barberia_id_actual())
  );

create policy barberias_insert_superadmin on barberias
  for insert with check (es_superadmin());

-- ----------------------------------------------------------------------------
-- sucursales
-- ----------------------------------------------------------------------------

alter table sucursales enable row level security;

create policy sucursales_select on sucursales
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy sucursales_escritura_admin on sucursales
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- perfiles
-- ----------------------------------------------------------------------------

alter table perfiles enable row level security;

create policy perfiles_select on perfiles
  for select using (
    id = auth.uid()
    or es_superadmin()
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

create policy perfiles_update_propio on perfiles
  for update using (id = auth.uid() or es_superadmin())
  with check (id = auth.uid() or es_superadmin());

create policy perfiles_insert_propio on perfiles
  for insert with check (id = auth.uid());

-- ----------------------------------------------------------------------------
-- barberos
-- ----------------------------------------------------------------------------

alter table barberos enable row level security;

create policy barberos_select on barberos
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy barberos_escritura_admin on barberos
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- horarios_barbero
-- ----------------------------------------------------------------------------

alter table horarios_barbero enable row level security;

create policy horarios_barbero_select on horarios_barbero
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy horarios_barbero_escritura on horarios_barbero
  for all using (
    es_superadmin()
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
    or es_barbero_propietario(barbero_id)
  ) with check (
    es_superadmin()
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
    or es_barbero_propietario(barbero_id)
  );

-- ----------------------------------------------------------------------------
-- servicios
-- ----------------------------------------------------------------------------

alter table servicios enable row level security;

create policy servicios_select on servicios
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy servicios_escritura_admin on servicios
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- citas
-- ----------------------------------------------------------------------------

alter table citas enable row level security;

create policy citas_select on citas
  for select using (
    es_superadmin()
    or cliente_id = auth.uid()
    or es_barbero_propietario(barbero_id)
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

create policy citas_insert on citas
  for insert with check (
    barberia_id = obtener_barberia_id_actual()
    and (cliente_id = auth.uid() or es_admin_o_superior() or es_barbero_propietario(barbero_id))
  );

create policy citas_update on citas
  for update using (
    es_superadmin()
    or cliente_id = auth.uid()
    or es_barbero_propietario(barbero_id)
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- pagos
-- ----------------------------------------------------------------------------

alter table pagos enable row level security;

create policy pagos_select on pagos
  for select using (
    es_superadmin()
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
    or exists (select 1 from citas c where c.id = pagos.cita_id and c.cliente_id = auth.uid())
  );

create policy pagos_insert on pagos
  for insert with check (
    barberia_id = obtener_barberia_id_actual()
    and exists (
      select 1 from citas c
      where c.id = pagos.cita_id
        and (c.cliente_id = auth.uid() or es_admin_o_superior())
    )
  );

create policy pagos_update_admin on pagos
  for update using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- insumos
-- ----------------------------------------------------------------------------

alter table insumos enable row level security;

create policy insumos_select on insumos
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy insumos_escritura_admin on insumos
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- insumos_barbero
-- ----------------------------------------------------------------------------

alter table insumos_barbero enable row level security;

create policy insumos_barbero_select on insumos_barbero
  for select using (
    es_superadmin()
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
    or es_barbero_propietario(barbero_id)
  );

create policy insumos_barbero_escritura_admin on insumos_barbero
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- reportes_insumo
-- ----------------------------------------------------------------------------

alter table reportes_insumo enable row level security;

create policy reportes_insumo_select on reportes_insumo
  for select using (
    es_superadmin()
    or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
    or es_barbero_propietario(barbero_id)
  );

create policy reportes_insumo_insert on reportes_insumo
  for insert with check (
    barberia_id = obtener_barberia_id_actual() and es_barbero_propietario(barbero_id)
  );

create policy reportes_insumo_update_admin on reportes_insumo
  for update using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- promociones
-- ----------------------------------------------------------------------------

alter table promociones enable row level security;

create policy promociones_select on promociones
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy promociones_escritura_admin on promociones
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- configuraciones_barberia
-- ----------------------------------------------------------------------------

alter table configuraciones_barberia enable row level security;

create policy configuraciones_barberia_select on configuraciones_barberia
  for select using (
    es_superadmin() or barberia_id = obtener_barberia_id_actual()
  );

create policy configuraciones_barberia_escritura_admin on configuraciones_barberia
  for all using (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  ) with check (
    es_superadmin() or (es_admin_o_superior() and barberia_id = obtener_barberia_id_actual())
  );

-- ----------------------------------------------------------------------------
-- versiones_app (lectura pública, incluso sin sesión, para forzar actualización)
-- ----------------------------------------------------------------------------

alter table versiones_app enable row level security;

create policy versiones_app_select_publico on versiones_app
  for select using (true);

create policy versiones_app_escritura_superadmin on versiones_app
  for all using (es_superadmin()) with check (es_superadmin());
