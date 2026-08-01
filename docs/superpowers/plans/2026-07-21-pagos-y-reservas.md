# Plan de Implementación: Módulo de Reservas y Pagos QR

> Fecha: 2026-07-21
> Estado: Completado

## Pasos de Implementación
1. **Flujo de Reserva:** Implementar selección secuencial de sucursal -> servicio -> barbero -> fecha/hora.
2. **Cálculo de Disponibilidad:** Integrar función RPC `obtener_horarios_disponibles`.
3. **Subida de Comprobante QR:** Implementar `subir_comprobante_pago` con almacenamiento en bucket `imagenes-app`.
4. **Verificación Admin:** Integrar RPCs `confirmar_pago` y `rechazar_pago`.
