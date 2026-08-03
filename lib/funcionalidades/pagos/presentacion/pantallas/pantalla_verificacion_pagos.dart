import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/modelo_pago.dart';
import '../controladores/controlador_pagos.dart';

class PantallaVerificacionPagos extends ConsumerStatefulWidget {
  const PantallaVerificacionPagos({super.key});

  @override
  ConsumerState<PantallaVerificacionPagos> createState() =>
      _PantallaVerificacionPagosState();
}

class _PantallaVerificacionPagosState
    extends ConsumerState<PantallaVerificacionPagos> {
  // ltima lista conocida. El controlador pasa por `AsyncLoading()` (sin
  // valor previo) en cada confirmar/rechazar y termina en `AsyncError` si
  // falla, as que leer directo del `AsyncValue` hara desaparecer toda la
  // bandeja por el error de un solo tem. Cachear ac el ltimo dato bueno
  // evita eso: la lista se sigue mostrando y el error solo se avisa aparte.
  List<ModeloPago>? _ultimosPagosConocidos;
  String? _procesandoPagoId;

  @override
  Widget build(BuildContext context) {
    final pagosState = ref.watch(controladorPagosPorVerificarProvider);
    if (pagosState.hasValue) {
      _ultimosPagosConocidos = pagosState.value;
    }
    final pagos = _ultimosPagosConocidos;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorPagosPorVerificarProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
      if (!siguiente.isLoading && _procesandoPagoId != null) {
        setState(() => _procesandoPagoId = null);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar pagos')),
      body: pagos == null
          ? _cuerpoCargaInicial(pagosState, colorScheme)
          : _cuerpoLista(pagos, pagosState, colorScheme),
    );
  }

  /// Todava no hay ningn dato bueno cacheado: o est cargando por primera
  /// vez, o esa primera carga fall.
  Widget _cuerpoCargaInicial(
    AsyncValue<List<ModeloPago>> pagosState,
    ColorScheme colorScheme,
  ) {
    if (pagosState.hasError) {
      return Center(
        child: Text(
          pagosState.error.toString(),
          style: TextStyle(color: colorScheme.error),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _cuerpoLista(
    List<ModeloPago> pagos,
    AsyncValue<List<ModeloPago>> pagosState,
    ColorScheme colorScheme,
  ) {
    if (pagos.isEmpty && !pagosState.isLoading) {
      return Center(
        child: Text(
          'No hay pagos pendientes de verificacin.',
          style: TipografiaApp.bodyMd.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (pagosState.isLoading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pagos.length,
            itemBuilder: (context, index) {
              final pago = pagos[index];
              return _TarjetaPagoPorVerificar(
                pago: pago,
                procesando: _procesandoPagoId == pago.id,
                bloqueadaPorOtraOperacion:
                    _procesandoPagoId != null && _procesandoPagoId != pago.id,
                onConfirmar: () => _confirmar(pago.id),
                onRechazar: () => _rechazar(pago.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmar(String pagoId) {
    // Guarda de reentrancia: el controlador solo tiene un `state` global (sin
    // tracking por-tem), as que solo puede haber UNA operacin en vuelo a
    // la vez en toda la pantalla. Si ya hay una (de esta tarjeta o de otra),
    // no arrancar una nueva: evita que dos llamadas pisen el mismo `state`.
    if (_procesandoPagoId != null) return;
    setState(() => _procesandoPagoId = pagoId);
    ref
        .read(controladorPagosPorVerificarProvider.notifier)
        .confirmarPago(pagoId)
        // El controlador relanza el error a propsito para que el caller
        // pueda reaccionar; ac el feedback ya se muestra va `ref.listen`
        // arriba, as que no hace falta reaccionar en este callback. El
        // catchError vaco es necesario solo para que Flutter no marque este
        // Future (disparado sin await) como "unhandled error" en la consola.
        .catchError((_) {});
  }

  void _rechazar(String pagoId) {
    if (_procesandoPagoId != null) return;
    setState(() => _procesandoPagoId = pagoId);
    ref
        .read(controladorPagosPorVerificarProvider.notifier)
        .rechazarPago(pagoId)
        .catchError((_) {});
  }
}

class _TarjetaPagoPorVerificar extends StatelessWidget {
  const _TarjetaPagoPorVerificar({
    required this.pago,
    required this.procesando,
    required this.bloqueadaPorOtraOperacion,
    required this.onConfirmar,
    required this.onRechazar,
  });

  final ModeloPago pago;
  final bool procesando;
  // Hay OTRA tarjeta procesando (el controlador es global: solo admite una
  // operacin en vuelo por vez en toda la pantalla). Deshabilita los botones
  // sin mostrar spinner, para no sugerir que esta tarjeta est trabajando.
  final bool bloqueadaPorOtraOperacion;
  final VoidCallback onConfirmar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deshabilitada = procesando || bloqueadaPorOtraOperacion;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pago.nombreCliente ?? 'Cliente',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (pago.fechaHoraCita != null)
              Text(
                'Cita: ${formatoFechaHora(pago.fechaHoraCita!.toLocal())}',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              formatoMoneda(pago.monto),
              style: TipografiaApp.bodyMd.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (pago.urlComprobante != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: pago.urlComprobante!,
                  placeholder: (context, url) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No se pudo cargar el comprobante',
                          style: TipografiaApp.bodyMd.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (procesando)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                TextButton(
                  onPressed: deshabilitada ? null : onRechazar,
                  child: Text(
                    'Rechazar',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: deshabilitada ? null : onConfirmar,
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
