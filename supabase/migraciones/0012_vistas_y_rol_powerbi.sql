-- ============================================================================
-- BarberApp - Migración 0012: Vistas Curadas de Reportes y Rol PowerBI
-- ============================================================================

-- ----------------------------------------------------------------------------
-- vista_reportes_citas (Vista desanonimizada/curada de citas para PowerBI)
-- ----------------------------------------------------------------------------

create or replace view vista_reportes_citas as
select
  c.id as cita_id,
  c.barberia_id,
  c.sucursal_id,
  s.nombre as sucursal_nombre,
  serv.nombre as servicio_nombre,
  serv.precio as servicio_precio_lista,
  c.precio_cobrado,
  c.estado as cita_estado,
  c.fecha_hora,
  c.creado_en
from citas c
left join sucursales s on s.id = c.sucursal_id
left join servicios serv on serv.id = c.servicio_id;

-- ----------------------------------------------------------------------------
-- vista_reportes_servicios (Métricas agregadas por servicio)
-- ----------------------------------------------------------------------------

create or replace view vista_reportes_servicios as
select
  serv.id as servicio_id,
  serv.barberia_id,
  serv.nombre as servicio_nombre,
  serv.precio as precio_lista,
  count(c.id) as total_citas,
  count(c.id) filter (where c.estado = 'completada') as citas_completadas,
  coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as total_recaudado
from servicios serv
left join citas c on c.servicio_id = serv.id
group by serv.id, serv.barberia_id, serv.nombre, serv.precio;

-- ----------------------------------------------------------------------------
-- vista_reportes_barberos (Métricas agregadas por barbero)
-- ----------------------------------------------------------------------------

create or replace view vista_reportes_barberos as
select
  b.id as barbero_id,
  b.barberia_id,
  p.nombre as barbero_nombre,
  count(c.id) as total_citas,
  count(c.id) filter (where c.estado = 'completada') as citas_completadas,
  coalesce(sum(c.precio_cobrado) filter (where c.estado = 'completada'), 0) as total_ingresos
from barberos b
join perfiles p on p.id = b.perfil_id
left join citas c on c.barbero_id = b.id
group by b.id, b.barberia_id, p.nombre;

-- ----------------------------------------------------------------------------
-- Rol de Solo Lectura para PowerBI (lector_reportes_powerbi)
-- ----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'lector_reportes_powerbi') then
    create role lector_reportes_powerbi with login password 'barberia-app2026';
  else
    alter role lector_reportes_powerbi with password 'barberia-app2026';
  end if;
end
$$;

grant usage on schema public to lector_reportes_powerbi;
grant select on vista_reportes_citas to lector_reportes_powerbi;
grant select on vista_reportes_servicios to lector_reportes_powerbi;
grant select on vista_reportes_barberos to lector_reportes_powerbi;
