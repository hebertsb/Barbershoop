-- ============================================================================
-- BarberApp - Datos de Prueba Iniciales (Seed Data)
-- ============================================================================

-- 1. Barbería Principal
insert into barberias (id, nombre, id_licencia, activo)
values (
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'Barbería Elite Club',
  'LIC-ELITE-2026',
  true
) on conflict (id) do nothing;

-- 2. Sucursales
insert into sucursales (id, barberia_id, nombre, direccion, telefono, activo)
values 
  ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Sucursal Central', 'Av. Principal #123, Zona Central', '+591 70000001', true),
  ('b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Sucursal Norte', 'Calle Comercial #456, Equipetrol', '+591 70000002', true)
on conflict (id) do nothing;

-- 3. Servicios
insert into servicios (id, barberia_id, nombre, descripcion, precio, duracion_minutos, activo)
values 
  ('c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Corte Clásico & Estilo', 'Corte de cabello personalizado con lavado y peinado final.', 50.00, 30, true),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a15', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Perfilado & Ritual de Barba', 'Ritual con toalla caliente, perfilado con navaja y bálsamo hidratante.', 40.00, 25, true),
  ('c3eebc99-9c0b-4ef8-bb6d-6bb9bd380a16', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Combo Completo (Corte + Barba)', 'Servicio premium de corte y barba con mascarilla negra gratis.', 80.00, 50, true),
  ('c4eebc99-9c0b-4ef8-bb6d-6bb9bd380a17', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Limpieza Facial Express', 'Exfoliación profunda e hidratación fácil en 20 minutos.', 35.00, 20, true)
on conflict (id) do nothing;

-- 4. Promociones
insert into promociones (id, barberia_id, titulo, descripcion, descuento, codigo, activo)
values 
  ('d1eebc99-9c0b-4ef8-bb6d-6bb9bd380a18', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Descuento Bienvenida', '15% de descuento en tu primera cita.', 15.00, 'BIENVENIDA15', true)
on conflict (id) do nothing;

-- 5. Programa de Fidelidad
insert into programas_fidelidad (id, barberia_id, titulo, descripcion, citas_requeridas, premio, activo)
values 
  ('e1eebc99-9c0b-4ef8-bb6d-6bb9bd380a19', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Tarjeta Fidelidad Elite', 'Acumulá 5 visitas y la 6ta cita es gratis.', 5, 'Corte de Cabello Gratis', true)
on conflict (id) do nothing;
