import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../ajustes/dominio/enum_modo_pago.dart';
import '../../../ajustes/presentacion/controladores/controlador_ajustes_pagos.dart';
import '../../../citas/dominio/modelo_cita.dart';
import '../controladores/controlador_reserva.dart';

import '../../../promociones/dominio/enum_tipo_descuento.dart';

class PantallaConfirmacionReserva extends ConsumerStatefulWidget {
  const PantallaConfirmacionReserva({super.key});

  @override
  ConsumerState<PantallaConfirmacionReserva> createState() =>
      _PantallaConfirmacionReservaState();
}

class _PantallaConfirmacionReservaState
    extends ConsumerState<PantallaConfirmacionReserva> {
  bool _confirmando = false;
  String? _errorMensaje;

  ModeloServicio? _buscarServicio(
    List<ModeloServicio> servicios,
    String? servicioId,
  ) {
    final candidatos = servicios.where((s) => s.id == servicioId).toList();
    return candidatos.isEmpty ? null : candidatos.first;
  }

  Future<void> _confirmar() async {
    if (_confirmando) return;
    setState(() {
      _confirmando = true;
      _errorMensaje = null;
    });

    ModeloCita? cita;
    try {
      final resultado = await ref
          .read(controladorReservaProvider.notifier)
          .confirmar();
      cita = resultado.cita;
      if (!mounted) return;
      ref.read(controladorReservaProvider.notifier).reiniciar();

      final config = await ref.read(controladorAjustesPagosProvider.future);
      if (!mounted) return;

      final servicios = ref.read(controladorServiciosProvider).value ?? [];
      final servicio = _buscarServicio(servicios, cita.servicioId);
      final monto = config.calcularMontoAPagar(servicio?.precio);
      final requierePago =
          config.modo == ModoPago.obligatorio || config.modo == ModoPago.sena;

      if (requierePago && monto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu cita se reservó. Contactá al local para coordinar tu pago.',
            ),
          ),
        );
        context.go('/mis-citas');
        return;
      }

      if (requierePago) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reserva confirmada! Ahora pagá por QR para asegurarla.'),
          ),
        );
        context.push(
          '/pago/${cita.id}',
          extra: {'monto': monto!, 'urlQrBanco': config.urlQrBanco},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reserva confirmada!')),
        );
        context.go('/mis-citas');
      }
    } catch (e) {
      if (!mounted) return;
      if (cita != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu cita se reservó, pero hubo un problema al preparar el pago. Revisá "Mis citas".',
            ),
          ),
        );
        context.go('/mis-citas');
      } else {
        setState(() => _errorMensaje = e.toString());
      }
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorReservaProvider);
    final servicios = ref.watch(controladorServiciosProvider).value ?? [];
    final barberos = ref.watch(barberosPublicosProvider).value ?? [];
    final modoPago = ref.watch(controladorAjustesPagosProvider).value?.modo;
    final colorScheme = Theme.of(context).colorScheme;

    final servicio = _buscarServicio(servicios, estado.servicioId);
    final promo = estado.promocion;

    String nombreServicio = servicio?.nombre ?? 'Servicio de Barbería';
    if (promo != null) {
      nombreServicio = '${servicio?.nombre ?? "Servicio"} (${promo.titulo})';
    }

    String nombreBarbero;
    if (estado.cualquieraSeleccionado) {
      nombreBarbero = 'Cualquiera disponible';
    } else {
      final candidatosBarbero =
          barberos.where((b) => b.id == estado.barberoId).toList();
      nombreBarbero = candidatosBarbero.isEmpty
          ? 'Barbero'
          : (candidatosBarbero.first.nombrePerfil ?? 'Barbero');
    }

    final double precioOriginal = servicio?.precio ?? 0.0;
    double montoFinal = precioOriginal;
    double descuentoMonto = 0.0;

    if (promo != null) {
      if (promo.tipoDescuento == TipoDescuento.porcentaje) {
        descuentoMonto = precioOriginal * (promo.valorDescuento / 100);
        montoFinal = (precioOriginal - descuentoMonto).clamp(0, double.infinity);
      } else {
        descuentoMonto = promo.valorDescuento;
        montoFinal = (precioOriginal - descuentoMonto).clamp(0, double.infinity);
      }
    }

    final bool tieneDescuento = descuentoMonto > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card en Formato TICKET DE RESERVA
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Banner Cabecera
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TICKET DE RESERVA',
                          style: TipografiaApp.labelMd.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Cuerpo del Ticket
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SERVICIO',
                          style: TipografiaApp.labelSm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nombreServicio,
                          style: TipografiaApp.headlineSm.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Barbero: ',
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              nombreBarbero,
                              style: TipografiaApp.bodyMd.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fecha y Hora: ',
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                estado.fechaHora != null
                                    ? formatoFechaHora(
                                        estado.fechaHora!.toLocal(),
                                      )
                                    : 'Sin fecha',
                                style: TipografiaApp.bodyMd.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),

                        // Subtotal y Descuento si aplica
                        if (tieneDescuento) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TipografiaApp.bodySm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                formatoMoneda(precioOriginal),
                                style: TipografiaApp.bodySm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Descuento Promoción',
                                style: TipografiaApp.bodySm.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '- ${formatoMoneda(descuentoMonto)}',
                                style: TipografiaApp.bodySm.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                        ],

                        // TOTAL A PAGAR RESALTADO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL A PAGAR',
                              style: TipografiaApp.headlineSm.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatoMoneda(montoFinal),
                              style: TipografiaApp.headlineSm.copyWith(
                                color: ColoresApp.primario,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Caja Informativa de Pago
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    modoPago == ModoPago.obligatorio ||
                            modoPago == ModoPago.sena
                        ? Icons.qr_code_2_rounded
                        : Icons.store_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      modoPago == ModoPago.obligatorio ||
                              modoPago == ModoPago.sena
                          ? 'Se requiere confirmación mediante pago de Código QR.'
                          : 'Se paga en el local al momento del servicio.',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMensaje != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMensaje!,
                style: TextStyle(color: colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            // Botón Confirmar Reserva
            ElevatedButton.icon(
              onPressed: _confirmando ? null : _confirmar,
              icon: _confirmando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 22),
              label: Text(
                _confirmando ? 'Reservando...' : 'CONFIRMAR RESERVA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.primario,
                foregroundColor: colorScheme.onPrimaryContainer,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
