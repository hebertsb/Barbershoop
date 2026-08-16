import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../dominio/enum_tipo_descuento.dart';
import '../../dominio/modelo_promocion.dart';

String _formatoFechaValidez(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  final y = fecha.year.toString();
  const dias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  final dia = dias[fecha.weekday - 1];
  return '$dia $d/$m/$y';
}

/// Tarjeta de promoción para el carrusel horizontal del panel cliente.
class TarjetaPromocionCliente extends ConsumerWidget {
  const TarjetaPromocionCliente({
    super.key,
    required this.promocion,
    required this.onReservar,
  });

  final ModeloPromocion promocion;
  final VoidCallback onReservar;

  void _abrirModalDetalles(BuildContext context, WidgetRef ref) {
    final servicios = ref.read(controladorServiciosProvider).value ?? [];
    final serviciosIncluidos = servicios
        .where((s) => promocion.serviciosIds.contains(s.id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalDetallePromocion(
        promocion: promocion,
        serviciosIncluidos: serviciosIncluidos,
        onReservar: () {
          Navigator.pop(ctx);
          onReservar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textoDescuento = promocion.tipoDescuento == TipoDescuento.porcentaje
        ? '-${promocion.descuento.toStringAsFixed(0)}%'
        : '-Bs. ${promocion.descuento.toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () => _abrirModalDetalles(context, ref),
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen con badge de descuento y banner "VÁLIDO HASTA..."
            Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: promocion.imagen != null
                      ? CachedNetworkImage(
                          imageUrl: promocion.imagen!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: colorScheme.primaryContainer,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _FondoSinImagen(colorScheme: colorScheme),
                        )
                      : _FondoSinImagen(colorScheme: colorScheme),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                if (promocion.fechaFin != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VÁLIDO HASTA ${_formatoFechaValidez(promocion.fechaFin!)}',
                        style: TipografiaApp.labelSm.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.estadoCompletada,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      textoDescuento,
                      style: TipografiaApp.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Contenido: título, descripción y botón
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    promocion.titulo,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.content_cut,
                        size: 14,
                        color: ColoresApp.primario,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          promocion.esCombo
                              ? 'Combo de ${promocion.serviciosIds.length} servicios'
                              : (promocion.serviciosIds.isNotEmpty
                                  ? 'Válido para servicios seleccionados'
                                  : 'Válido para cualquier servicio'),
                          style: TipografiaApp.bodySm.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (promocion.descripcion != null &&
                      promocion.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      promocion.descripcion!,
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _abrirModalDetalles(context, ref),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColoresApp.primario),
                        foregroundColor: ColoresApp.primario,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'VER DETALLES',
                        style: TipografiaApp.labelSm.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalDetallePromocion extends StatelessWidget {
  const _ModalDetallePromocion({
    required this.promocion,
    required this.serviciosIncluidos,
    required this.onReservar,
  });

  final ModeloPromocion promocion;
  final List<dynamic> serviciosIncluidos;
  final VoidCallback onReservar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textoDescuento = promocion.tipoDescuento == TipoDescuento.porcentaje
        ? '-${promocion.descuento.toStringAsFixed(0)}% DE DESCUENTO'
        : '-Bs. ${promocion.descuento.toStringAsFixed(0)} DE DESCUENTO';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen grande
                  if (promocion.imagen != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: promocion.imagen!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Badge Descuento
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.estadoCompletada,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      textoDescuento,
                      style: TipografiaApp.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Título
                  Text(
                    promocion.titulo,
                    style: TipografiaApp.headlineSm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  if (promocion.descripcion != null &&
                      promocion.descripcion!.isNotEmpty) ...[
                    Text(
                      promocion.descripcion!,
                      style: TipografiaApp.bodyMd.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 12),

                  // Servicios Incluidos
                  Text(
                    'SERVICIOS INCLUIDOS EN ESTA OFERTA',
                    style: TipografiaApp.labelSm.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (serviciosIncluidos.isNotEmpty)
                    ...serviciosIncluidos.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: ColoresApp.primario,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.nombre ?? 'Servicio',
                                style: TipografiaApp.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'Bs. ${s.precio.toStringAsFixed(2)}',
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aplica para cualquier servicio individual de la barbería.',
                            style: TipografiaApp.bodyMd.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Validez
                  if (promocion.fechaFin != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Válido hasta: ',
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          formatoFechaHora(promocion.fechaFin!.toLocal()),
                          style: TipografiaApp.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Botón RECLAMAR OFERTA
                  ElevatedButton.icon(
                    onPressed: onReservar,
                    icon: const Icon(Icons.local_offer, size: 22),
                    label: const Text(
                      'RECLAMAR OFERTA Y RESERVAR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.primario,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FondoSinImagen extends StatelessWidget {
  const _FondoSinImagen({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.local_offer_outlined,
          size: 40,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
