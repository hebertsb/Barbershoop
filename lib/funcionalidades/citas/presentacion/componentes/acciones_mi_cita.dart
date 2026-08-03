import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../pagos/dominio/enum_estado_pago.dart';
import '../../../pagos/presentacion/controladores/controlador_pagos.dart';
import '../../../reservas/presentacion/controladores/controlador_reserva.dart';
import '../../dominio/modelo_cita.dart';
import '../controladores/controlador_mis_citas.dart';

/// Botones "Cancelar"/"Reprogramar" pensados como pie de [TarjetaMiCita]
/// (mismo criterio que [EstadoPagoCita]: componente aparte porque necesita
/// leer providers, cosa que la tarjeta en s no hace)  quien arma la lista
/// (`PantallaMisCitas`) decide mostrarlo solo para citas `pendiente`.
///
/// "Cancelar" pide confirmacin con un `AlertDialog`; si el pago de la cita
/// ya est `confirmado` (va `controladorPagoDeCitaProvider`), el dilogo
/// suma el aviso de que no hay reembolso automtico antes de dejar
/// confirmar. "Reprogramar" avisa que la cita actual se cancela recin
/// cuando la nueva se confirme, y manda al wizard de reserva ya precargado
/// (`ControladorReserva.iniciarReprogramacion`) directo a elegir barbero.
class AccionesMiCita extends ConsumerWidget {
  const AccionesMiCita({super.key, required this.cita});

  final ModeloCita cita;

  Future<void> _cancelar(
    BuildContext context,
    WidgetRef ref,
    bool pagoConfirmado,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text(
          pagoConfirmado
              ? 'Seguro que quers cancelar esta cita?\n\n'
                    'Tu pago no se reembolsa automticamente. Si ya pagaste, '
                    'contact al local.'
              : 'Seguro que quers cancelar esta cita?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      await ref.read(controladorMisCitasProvider.notifier).cancelar(cita.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cita cancelada.')));
    } catch (e) {
      if (!context.mounted) return;
      // Los mensajes de `cancelar_cita_cliente` ya vienen listos para el
      // usuario tal cual (ver 0031_cancelar_cita_cliente.sql).
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reprogramar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reprogramar cita'),
        content: const Text(
          'Vas a elegir un nuevo horario. Tu cita actual se cancelar '
          'automticamente al confirmar la nueva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    ref
        .read(controladorReservaProvider.notifier)
        .iniciarReprogramacion(
          sucursalId: cita.sucursalId ?? '',
          servicioId: cita.servicioId,
          citaIdAReemplazar: cita.id,
        );
    context.push('/reservar/barbero');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observa ac (no solo `read` dentro de los dilogos) para que el
    // valor est resuelto de antemano en el caso normal: `EstadoPagoCita`
    // (pie de la misma tarjeta) ya mantiene vivo este mismo provider por
    // `citaId` mientras la cita est en pantalla.
    final pago = ref.watch(controladorPagoDeCitaProvider(cita.id)).valueOrNull;
    final pagoConfirmado = pago != null && pago.estado == EstadoPago.confirmado;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelar(context, ref, pagoConfirmado),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _reprogramar(context, ref),
            child: const Text('Reprogramar'),
          ),
        ),
      ],
    );
  }
}
