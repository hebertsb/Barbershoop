import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../pagos/dominio/enum_estado_pago.dart';
import '../../../pagos/dominio/modelo_pago.dart';
import '../../../pagos/presentacion/componentes/formulario_cobro.dart';
import '../../../pagos/presentacion/controladores/controlador_pagos.dart';
import '../../../turnos/dominio/modelo_turno.dart';
import '../../../turnos/presentacion/controladores/controlador_turnos.dart';
import '../../dominio/modelo_cita.dart';

/// Cierra un turno (marca completado) resolviendo el cobro segun 4 casos:
/// pago QR confirmado que ya cubre el precio, saldo pendiente de una sena,
/// cobro en efectivo/otro metodo, o turno con monto ya precobrado. Mismo
/// pipeline que ya usaba `PantallaAgenda` (admin/secretaria) -- se
/// comparte para no tener dos copias de logica de dinero que puedan
/// divergir; lo reusa tambien `PantallaAgendaBarbero`.
Future<void> completarTurnoConCobro({
  required BuildContext context,
  required WidgetRef ref,
  required String sucursalId,
  required String turnoId,
  required List<ModeloTurno> turnos,
  required List<ModeloServicio> servicios,
  required List<ModeloCita> citas,
}) async {
  final turno = turnos.firstWhere((t) => t.id == turnoId);
  if (turno.montoPrecobrado != null) {
    ref
        .read(controladorTurnosProvider(sucursalId).notifier)
        .completarTurno(turnoId: turnoId)
        .catchError((_) => '');
    return;
  }
  final candidatos = servicios.where((s) => s.id == turno.servicioId).toList();
  final servicio = candidatos.isEmpty ? null : candidatos.first;
  final precioServicioCatalogo = servicio?.precio ?? 0;

  // El precio de referencia SIEMPRE debe ser el total real de la cita
  // (`citas.precio_cobrado`, calculado por `reservar_cita` sumando TODOS
  // los servicios de un combo + descuento de promo aplicado) y no el
  // precio de un solo servicio del catalogo -- `turno.servicioId` (copiado
  // de `citas.servicio_id`) solo guarda el PRIMER servicio de un combo por
  // diseno (ver 0040_reservar_cita_combos.sql). Para una cita simple da lo
  // mismo; para un combo, usar solo el precio del catalogo sub-cobra o hace
  // creer que ya esta pagado completo. Fallback al precio de catalogo si es
  // walk-in puro (turno.citaId null, sin combo posible) o si por algun
  // motivo no se encuentra la cita/su precio_cobrado en la lista pasada.
  final citaId = turno.citaId;
  final citasCoincidentes = citaId == null
      ? const <ModeloCita>[]
      : citas.where((c) => c.id == citaId).toList();
  final citaEnlazada = citasCoincidentes.isEmpty ? null : citasCoincidentes.first;
  final precioServicio = citaEnlazada?.precioCobrado ?? precioServicioCatalogo;

  var fallaVerificacionPago = false;
  if (citaId != null) {
    ModeloPago? pago;
    try {
      pago = await ref.read(controladorPagoDeCitaProvider(citaId).future);
    } catch (_) {
      pago = null;
      fallaVerificacionPago = true;
    }
    if (pago != null && pago.estado == EstadoPago.confirmado) {
      if (pago.monto >= precioServicio) {
        if (!context.mounted) return;
        _mostrarDialogoYaPagado(
          context: context,
          ref: ref,
          sucursalId: sucursalId,
          turnoId: turnoId,
          montoPagado: pago.monto,
        );
        return;
      }
      if (!context.mounted) return;
      _mostrarFormularioCobro(
        context: context,
        ref: ref,
        sucursalId: sucursalId,
        turnoId: turnoId,
        precioSugerido: precioServicio - pago.monto,
        etiquetaMonto: 'Saldo pendiente (Bs.) *',
      );
      return;
    }
  }

  if (!context.mounted) return;
  if (fallaVerificacionPago) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo verificar si esta cita ya tiene un pago registrado. '
          'Revisá antes de cobrar.',
        ),
      ),
    );
  }
  _mostrarFormularioCobro(
    context: context,
    ref: ref,
    sucursalId: sucursalId,
    turnoId: turnoId,
    precioSugerido: precioServicio,
  );
}

void _mostrarDialogoYaPagado({
  required BuildContext context,
  required WidgetRef ref,
  required String sucursalId,
  required String turnoId,
  required double montoPagado,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cita ya pagada'),
      content: Text(
        'Esta cita ya fue pagada por QR (Bs. ${montoPagado.toStringAsFixed(2)}). '
        '¿Marcar como completada?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ref
                .read(controladorTurnosProvider(sucursalId).notifier)
                .completarTurno(turnoId: turnoId)
                .catchError((_) => '');
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}

void _mostrarFormularioCobro({
  required BuildContext context,
  required WidgetRef ref,
  required String sucursalId,
  required String turnoId,
  required double precioSugerido,
  String? etiquetaMonto,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => FormularioCobro(
      precioSugerido: precioSugerido,
      etiquetaMonto: etiquetaMonto,
      alConfirmar: (monto, metodo) => ref
          .read(controladorTurnosProvider(sucursalId).notifier)
          .completarTurno(turnoId: turnoId, monto: monto, metodo: metodo)
          .then((_) {}),
    ),
  );
}
