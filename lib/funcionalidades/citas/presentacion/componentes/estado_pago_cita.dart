import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../ajustes/dominio/enum_modo_pago.dart';
import '../../../pagos/dominio/enum_estado_pago.dart';
import '../../../pagos/presentacion/controladores/controlador_pagos.dart';
import 'etiqueta_estado.dart';

/// Indicador de estado de pago + botn para ir a `PantallaPagoQr`, pensado
/// como pie de [TarjetaMiCita] para citas `pendiente`.
///
/// Consulta el pago de la cita va `controladorPagoDeCitaProvider` (family
/// por `citaId`, ya usado por `PantallaPagoQr`) para decidir qu mostrar:
/// - Sin pago todava: aviso "Pago pendiente" solo si el modo configurado
///   efectivamente lo exige (obligatorio/sea); en modo opcional se ofrece
///   el botn igual, pero sin aviso de alerta.
/// - `por_verificar`/`rechazado`: aviso correspondiente y botn para ver el
///   estado o reintentar la subida del comprobante.
/// - `confirmado` (o todava cargando): no hay nada que el cliente deba
///   hacer, as que no se muestra nada.
///
/// [monto] llega ya resuelto por quien invoca (va
/// `ModeloConfiguracionPagos.calcularMontoAPagar`) y puede ser `null` si
/// todava no se puede calcular un monto vlido (ej. el servicio no
/// termin de cargar). En ese caso el botn de pago se oculta  nunca se
/// navega a `PantallaPagoQr` con un monto de $0  y aparece solo, sin
/// bloquear nada, en el prximo rebuild cuando [monto] deje de ser `null`.
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

    // Carga inicial sin dato previo: nada que mostrar todava, evita un
    // parpadeo del indicador/botn mientras resuelve.
    if (pagoState.isLoading && !pagoState.hasValue) {
      return const SizedBox.shrink();
    }
    // Pago ya confirmado: no hay accin pendiente para el cliente.
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
      textoIndicador = 'Pago en verificacin';
      colorIndicador = colores.pendiente;
      textoBoton = 'Ver estado del pago';
    } else if (modoPago == ModoPago.obligatorio || modoPago == ModoPago.sena) {
      textoIndicador = 'Pago pendiente';
      colorIndicador = colores.pendiente;
    }

    // Sin un monto vlido no hay a dnde navegar: se oculta el botn en vez
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
