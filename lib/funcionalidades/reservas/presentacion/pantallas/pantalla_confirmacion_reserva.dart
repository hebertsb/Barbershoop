import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  /// Busca un servicio por id, tolerando que no se encuentre (borrado o
  /// desactivado, o lista aún no cargada).
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

    // Una vez que la cita queda creada en la DB, la reserva es un hecho
    // irreversible desde el cliente: ningún fallo posterior debe permitir
    // reintentar `confirmar()` (crearía una segunda cita para el mismo
    // horario). Por eso se guarda acá y el catch la usa para decidir cómo
    // reaccionar.
    ModeloCita? cita;
    try {
      final resultado = await ref
          .read(controladorReservaProvider.notifier)
          .confirmar();
      cita = resultado.cita;
      if (!mounted) return;
      // La cita ya existe: reiniciar el estado de inmediato, antes de tocar
      // cualquier otra cosa que pueda fallar (config de pagos, precio, nav).
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
              'Tu cita se reservó. No pudimos calcular el monto a pagar '
              'automáticamente, contactá al local.',
            ),
          ),
        );
        context.go('/mis-citas');
        return;
      }

      if (requierePago) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reserva confirmada! Ahora pagá para asegurarla.'),
          ),
        );
        // `push` (no `go`): deja esta pantalla en el stack para que
        // `PantallaPagoQr` reciba la flecha de "volver" automática del
        // AppBar y el gesto de back del sistema funcione. Si el cliente
        // vuelve para acá, el estado de la reserva ya fue reiniciado arriba
        // y "Confirmar reserva" fallará con un mensaje claro (no reintenta
        // la reserva ni crea una cita duplicada).
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
        // La cita ya se reservó antes del fallo: no hay nada que
        // "reintentar", solo informar y mandar a Mis citas.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu cita se reservó, pero hubo un problema al preparar el '
              'pago. Revisá "Mis citas".',
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

    String nombreBarbero;
    if (estado.cualquieraSeleccionado) {
      nombreBarbero = 'Cualquiera disponible';
    } else {
      final candidatosBarbero =
          barberos.where((b) => b.id == estado.barberoId).toList();
      nombreBarbero =
          candidatosBarbero.isEmpty ? 'Barbero' : (candidatosBarbero.first.nombrePerfil ?? 'Barbero');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar reserva')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio?.nombre ?? 'Servicio',
                      style: TipografiaApp.headlineSm.copyWith(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Con $nombreBarbero',
                      style: TipografiaApp.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (estado.fechaHora != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        formatoFechaHora(estado.fechaHora!.toLocal()),
                        style: TipografiaApp.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (servicio != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        formatoMoneda(servicio.precio),
                        style: TipografiaApp.bodyMd.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              modoPago == ModoPago.obligatorio || modoPago == ModoPago.sena
                  ? 'Vas a pagar por QR después de confirmar.'
                  : 'Se paga en el local al momento del servicio.',
              style: TipografiaApp.bodySm.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (_errorMensaje != null) ...[
              const SizedBox(height: 16),
              Text(_errorMensaje!, style: TextStyle(color: colorScheme.error)),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _confirmando ? null : _confirmar,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _confirmando
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar reserva'),
            ),
          ],
        ),
      ),
    );
  }
}
