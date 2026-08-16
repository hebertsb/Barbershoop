import 'dart:async';
import 'dart:convert';
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
    final pago = pagoState.valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    final esCargaInicial = pagoState.isLoading && !pagoState.hasValue;

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
          ref.invalidate(controladorPagoDeCitaProvider(citaId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        width: 220,
                        height: 220,
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
                  'La barbería todavía no cargó su QR de pago.',
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 24),
              if (esCargaInicial)
                const Center(child: CircularProgressIndicator())
              else ...[
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

  Widget _construirImagenVisual(String url, ColorScheme colorScheme) {
    final urlLimpia = url.trim();
    if (urlLimpia.startsWith('http://') || urlLimpia.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: urlLimpia,
        fit: BoxFit.contain,
        placeholder: (context, u) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, u, error) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 40),
        ),
      );
    } else {
      try {
        final String base64Content = urlLimpia.contains(',')
            ? urlLimpia.split(',').last
            : urlLimpia;
        final bytes = base64Decode(base64Content.replaceAll(RegExp(r'\s+'), ''));
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, size: 40),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image_outlined, size: 40),
        );
      }
    }
  }

  /// Vista previa de imagen en tarjeta centrada (220x220), estilo idéntico al QR.
  Widget _tarjetaVistaPreviaComprobante({
    required BuildContext context,
    required String url,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: () => mostrarImagenPantallaCompleta(context, url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _construirImagenVisual(url, colorScheme),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selector de comprobante o el estado actual del pago.
  Widget _contenidoPago(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    ModeloPago? pago,
  ) {
    if (pago != null && pago.estado == EstadoPago.confirmado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade400, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  '¡PAGO CONFIRMADO!',
                  style: TipografiaApp.headlineSm.copyWith(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu pago fue verificado exitosamente por la barbería. Tu cita ya está asegurada.',
                  style: TipografiaApp.bodyMd.copyWith(
                    color: Colors.green.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (pago.urlComprobante != null) ...[
            const SizedBox(height: 20),
            Center(
              child: _tarjetaVistaPreviaComprobante(
                context: context,
                url: pago.urlComprobante!,
                colorScheme: colorScheme,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/mis-citas'),
            icon: const Icon(Icons.calendar_month),
            label: const Text('VER MIS CITAS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Volver al Inicio'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }

    if (pago != null && pago.estado == EstadoPago.porVerificar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comprobante en Verificación',
                        style: TipografiaApp.headlineSm.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tu comprobante fue subido. La barbería lo revisará a la brevedad.',
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (pago.urlComprobante != null) ...[
            const SizedBox(height: 20),
            Text(
              'Comprobante enviado (toca para ampliar):',
              textAlign: TextAlign.center,
              style: TipografiaApp.labelMd.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: _tarjetaVistaPreviaComprobante(
                context: context,
                url: pago.urlComprobante!,
                colorScheme: colorScheme,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/mis-citas'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Ir a Mis Citas'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Volver al Inicio'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
              'Tu comprobante anterior fue rechazado. Subí uno nuevo.',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        Text(
          'Subí la captura de tu comprobante de pago:',
          style: TipografiaApp.bodyMd.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SelectorImagen(
            bucket: Constantes.bucketImagenesApp,
            carpeta: 'comprobantes',
            ancho: 220,
            altura: 220,
            fit: BoxFit.contain,
            alSubir: (url) async {
              try {
                await ref
                    .read(controladorPagoDeCitaProvider(citaId).notifier)
                    .subirComprobante(monto: monto, urlComprobante: url);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Comprobante enviado! Revisa el estado en Mis Citas.'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go('/mis-citas');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al subir el comprobante: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
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
