# Especificación de Diseño: Módulo de Reservas y Pagos QR

> Fecha: 2026-07-21
> Estado: Aprobado

## Visión General
Proporciona el flujo de reserva de citas para clientes (selección de sucursal, servicio, barbero y horario) y la gestión de pagos mediante transferencias QR manuales con comprobante adjunto.

## Componentes y Arquitectura
1. **Dominio:** `ModeloCita`, `ModeloPago`, `EnumEstadoCita`, `EnumEstadoPago`, `EnumMetodoPago`.
2. **Datos:** `RepositorioReservas`, `RepositorioCitas`, `RepositorioPagos`.
3. **Presentación:**
   - `PantallaSeleccionServicio`: Listado interactivo de servicios.
   - `PantallaSeleccionBarbero`: Selección de profesional asignado.
   - `PantallaConfirmacionReserva`: Resumen final y creación de cita.
   - `PantallaMisCitas`: Historial e itinerario de citas del cliente.
   - `PantallaAgendaBarbero`: Vista diaria para barberos.
   - `PantallaPagoQR`: Subida de captura de transferencia bancaria.
   - `PantallaVerificacionPagos`: Panel admin para validar o rechazar comprobantes.
