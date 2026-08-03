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

class PantallaPagoQr extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final pagoState = ref.watch(controladorPagoDeCitaProvider(citaId));
    // El pago conocido ms reciente. A diferencia de `pagoState.when(...)`,
    // esto se mantiene disponible aunque el ltimo intento haya fallado, as
    // el error no tapa el resto de la UI (selector incluido).
    final pago = pagoState.valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    // Carga inicial: todava no hay ni dato ni error previos. Se distingue
    // de un reintento (tras error) o de un refresco (con dato previo), que
    // s deben seguir mostrando `_contenidoPago` con su banner correspondiente.
    final esCargaInicial =
        pagoState.isLoading && !pagoState.hasValue && !pagoState.hasError;

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar por QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Monto a pagar: ${formatoMoneda(monto)}',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (urlQrBanco != null) ...[
              Center(
                child: GestureDetector(
                  onTap: () =>
                      mostrarImagenPantallaCompleta(context, urlQrBanco!),
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
                        imageUrl: urlQrBanco!,
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
              Center(child: _BotonDescargarQr(urlQrBanco: urlQrBanco!)),
            ] else
              Text(
                'La barbera todava no carg su QR de pago.',
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
          Text(
            'Comprobante subido, esperando verificacin del local.',
            style: TipografiaApp.bodyMd.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
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
                .read(controladorPagoDeCitaProvider(citaId).notifier)
                .subirComprobante(monto: monto, urlComprobante: url)
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
