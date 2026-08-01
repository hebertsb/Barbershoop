import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../ajustes/dominio/enum_modo_pago.dart';
import '../../../pagos/dominio/enum_estado_pago.dart';
import '../../../pagos/presentacion/controladores/controlador_pagos.dart';
import 'etiqueta_estado.dart';

/// Indicador de estado de pago + botón para ir a `PantallaPagoQr`, pensado
/// como pie de [TarjetaMiCita] para citas `pendiente`.
///
/// Consulta el pago de la cita vía `controladorPagoDeCitaProvider` (family
/// por `citaId`, ya usado por `PantallaPagoQr`) para decidir qué mostrar:
/// - Sin pago todavía: aviso "Pago pendiente" solo si el modo configurado
///   efectivamente lo exige (obligatorio/seña); en modo opcional se ofrece
///   el botón igual, pero sin aviso de alerta.
/// - `por_verificar`/`rechazado`: aviso correspondiente y botón para ver el
///   estado o reintentar la subida del comprobante.
/// - `confirmado` (o todavía cargando): no hay nada que el cliente deba
///   hacer, así que no se muestra nada.
///
/// [monto] llega ya resuelto por quien invoca (vía
/// `ModeloConfiguracionPagos.calcularMontoAPagar`) y puede ser `null` si
/// todavía no se puede calcular un monto válido (ej. el servicio no
/// terminó de cargar). En ese caso el botón de pago se oculta — nunca se
/// navega a `PantallaPagoQr` con un monto de $0 — y aparece solo, sin
/// bloquear nada, en el próximo rebuild cuando [monto] deje de ser `null`.
class EstadoPagoCita extends ConsumerWidget {
  const EstadoPagoCita({
    super.key,
    required this.citaId,
    required this.modoPago,
    required this.monto,
    required this.urlQrBanco,
  });

  final String citaId;
  final ModoPago? modoPago;
  final double? monto;
  final String? urlQrBanco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagoState = ref.watch(controladorPagoDeCitaProvider(citaId));
    final pago = pagoState.valueOrNull;

    // Carga inicial sin dato previo: nada que mostrar todavía, evita un
    // parpadeo del indicador/botón mientras resuelve.
    if (pagoState.isLoading && !pagoState.hasValue) {
      return const SizedBox.shrink();
    }
    // Pago ya confirmado: no hay acción pendiente para el cliente.
    if (pago != null && pago.estado == EstadoPago.confirmado) {
      return const SizedBox.shrink();
    }

    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;
    String? textoIndicador;
    Color? colorIndicador;
    var textoBoton = 'Pagar por QR';

    if (pago != null && pago.estado == EstadoPago.rechazado) {
      textoIndicador = 'Pago rechazado';
      colorIndicador = colores.cancelada;
      textoBoton = 'Reintentar pago';
    } else if (pago != null && pago.estado == EstadoPago.porVerificar) {
      textoIndicador = 'Pago en verificación';
      colorIndicador = colores.pendiente;
      textoBoton = 'Ver estado del pago';
    } else if (modoPago == ModoPago.obligatorio || modoPago == ModoPago.sena) {
      textoIndicador = 'Pago pendiente';
      colorIndicador = colores.pendiente;
    }

    // Sin un monto válido no hay a dónde navegar: se oculta el botón en vez
    // de ofrecer un pago de $0 (mismo criterio que `PantallaConfirmacionReserva`).
    if (textoIndicador == null && monto == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (textoIndicador != null)
          EtiquetaEstado(texto: textoIndicador, color: colorIndicador!),
        const Spacer(),
        if (monto != null)
          TextButton(
            onPressed: () => context.push(
              '/pago/$citaId',
              extra: {'monto': monto!, 'urlQrBanco': urlQrBanco},
            ),
            child: Text(textoBoton),
          ),
      ],
    );
  }
}
