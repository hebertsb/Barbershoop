import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/componentes/visor_imagen_pantalla_completa.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/enum_estado_pago.dart';
import '../../dominio/modelo_pago.dart';
import '../controladores/controlador_pagos.dart';

class PantallaPagoQr extends ConsumerStatefulWidget {
  const PantallaPagoQr({
    super.key,
    required this.citaId,
    required this.monto,
    required this.urlQrBanco,
  });

  final String citaId;
  final double monto;
  final String? urlQrBanco;

  @override
  ConsumerState<PantallaPagoQr> createState() => _PantallaPagoQrState();
}

class _PantallaPagoQrState extends ConsumerState<PantallaPagoQr> {
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    // Refresca el estado del pago cada 5s para detectar cuando el admin
    // confirma el pago. Se cancela solo cuando el estado ya es terminal
    // (porVerificar o confirmado) para no seguir parpadeando innecesariamente.
    _timerRefresco = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final estadoActual =
          ref.read(controladorPagoDeCitaProvider(widget.citaId)).valueOrNull;
      final esTerminal = estadoActual != null &&
          (estadoActual.estado == EstadoPago.porVerificar ||
           estadoActual.estado == EstadoPago.confirmado);
      if (esTerminal) {
        _timerRefresco?.cancel();
        return;
      }
      ref.invalidate(controladorPagoDeCitaProvider(widget.citaId));
    });
  }

  @override
  void dispose() {
    _timerRefresco?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagoState = ref.watch(controladorPagoDeCitaProvider(widget.citaId));
    final pago = pagoState.valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    final esCargaInicial =
        pagoState.isLoading && !pagoState.hasValue && !pagoState.hasError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar por QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Volver al Inicio',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(controladorPagoDeCitaProvider(widget.citaId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Monto a pagar: ${formatoMoneda(widget.monto)}',
                style: TipografiaApp.headlineSm.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.urlQrBanco != null) ...[
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        mostrarImagenPantallaCompleta(context, widget.urlQrBanco!),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: CachedNetworkImage(
                          imageUrl: widget.urlQrBanco!,
                          fit: BoxFit.contain,
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
                                  'No se pudo cargar el QR',
                                  style: TipografiaApp.bodyMd.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca el QR para ampliarlo',
                  textAlign: TextAlign.center,
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _BotonDescargarQr(urlQrBanco: widget.urlQrBanco!)),
              ] else
                Text(
                  'La barbería todavía no cargó su QR de pago.',
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 24),
              if (esCargaInicial)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (pagoState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (pagoState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      pagoState.error.toString(),
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                _contenidoPago(context, ref, colorScheme, pago),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Selector de comprobante o el estado actual del pago, segn corresponda.
  /// Se basa en el ltimo [ModeloPago] conocido (no en el `AsyncValue`
  /// completo) para que un error de subida no oculte el selector.
  Widget _contenidoPago(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    ModeloPago? pago,
  ) {
    if (pago != null && pago.estado == EstadoPago.porVerificar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Comprobante subido. Esperando verificación del local.',
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (pago.urlComprobante != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 160,
                child: Image.network(
                  pago.urlComprobante!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const _BotonIrAMisCitas(),
        ],
      );
    }
    if (pago != null && pago.estado == EstadoPago.confirmado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pago confirmado!',
            style: TipografiaApp.bodyMd.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _BotonIrAMisCitas(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pago != null && pago.estado == EstadoPago.rechazado)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tu comprobante anterior fue rechazado. Sub uno nuevo.',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        Text(
          'Sub la captura de tu comprobante de pago',
          style: TipografiaApp.bodyMd.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SelectorImagen(
          bucket: Constantes.bucketImagenesApp,
          carpeta: 'comprobantes',
          alSubir: (url) {
            ref
                .read(controladorPagoDeCitaProvider(widget.citaId).notifier)
                .subirComprobante(monto: widget.monto, urlComprobante: url)
                // El controlador relanza el error a propsito para que el
                // caller pueda reaccionar; ac el feedback se muestra de
                // forma reactiva va `pagoState.hasError` arriba, as que
                // no hace falta reaccionar en este callback. El catchError
                // vaco es necesario solo para que Flutter no marque este
                // Future (disparado sin await desde un callback sncrono)
                // como "unhandled error" en la consola.
                .catchError((_) {});
          },
        ),
      ],
    );
  }
}

/// Botn para guardar el QR del banco en la galera del cliente, as puede
/// pagarlo desde la app de su banco en el mismo celular sin salir de
/// BarberApp. Usa el archivo ya cacheado por [CachedNetworkImage] (mismo
/// `flutter_cache_manager`) en vez de descargarlo de nuevo.
class _BotonDescargarQr extends StatefulWidget {
  const _BotonDescargarQr({required this.urlQrBanco});

  final String urlQrBanco;

  @override
  State<_BotonDescargarQr> createState() => _BotonDescargarQrState();
}

class _BotonDescargarQrState extends State<_BotonDescargarQr> {
  bool _descargando = false;

  Future<void> _descargarQr() async {
    setState(() => _descargando = true);
    try {
      final archivo = await DefaultCacheManager().getSingleFile(
        widget.urlQrBanco,
      );
      final bytes = await archivo.readAsBytes();
      await Gal.putImageBytes(
        bytes,
        name: 'qr-barberapp-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR guardado en tu galera')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar el QR: $e')));
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _descargando ? null : _descargarQr,
      icon: _descargando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined),
      label: Text(_descargando ? 'Descargando...' : 'Descargar QR'),
    );
  }
}

/// Salida explcita hacia `/mis-citas` para los estados de pago en los que
/// ya no queda nada por hacer en esta pantalla (comprobante subido o pago
/// confirmado). Complementa la flecha de "volver" del AppBar y el gesto de
/// back del sistema (disponibles porque esta pantalla se abre con
/// `context.push`), para que el cliente siempre tenga una salida obvia sin
/// depender de que sepa usar el back.
class _BotonIrAMisCitas extends StatelessWidget {
  const _BotonIrAMisCitas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/mis-citas'),
        child: const Text('Ir a Mis citas'),
      ),
    );
  }
}
