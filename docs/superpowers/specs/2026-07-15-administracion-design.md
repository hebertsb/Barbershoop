# Especificación de Diseño: Módulo de Administración

> Fecha: 2026-07-15
> Estado: Aprobado

## Visión General
Permite a los usuarios con rol `admin` o `superadmin` gestionar la infraestructura de su barbería: sucursales, catálogo de servicios, invitación de barberos, secretarias y configuración de horarios de atención.

## Componentes y Arquitectura
1. **Dominio:** `ModeloSucursal`, `ModeloServicio`, `ModeloBarbero`, `ModeloHorarioBarbero`, `ModeloSecretaria`.
2. **Datos:** `RepositorioAdministracion`, `RepositorioAccesosAdmin`.
3. **Presentación:**
   - `PantallaAdministracionDashboard`: Panel principal con gráfico de tendencia e accesos rápidos.
   - `PantallaGestionSucursales`: CRUD de sucursales por barbería.
   - `PantallaGestionServicios`: CRUD de servicios con precios y duraciones.
   - `PantallaGestionBarberos`: Invitación por email y asignación a sucursal.
   - `PantallaConfigurarHorarios`: Matriz semanal de disponibilidad por barbero.
