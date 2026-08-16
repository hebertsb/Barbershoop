import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../dominio/enum_tipo_descuento.dart';
import '../../dominio/modelo_promocion.dart';

String _formatoFechaValidezCorta(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final dia = dias[fecha.weekday - 1];
  return '$dia $d/$m';
}

String _formatoFechaValidezCompleta(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  final y = fecha.year.toString();
  const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
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
        width: 280,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen con badge de descuento y badge de vencimiento separado
            Stack(
              children: [
                SizedBox(
                  height: 120,
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
                // Degradado inferior
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Badge Descuento (esquina superior derecha)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.estadoCompletada,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          textoDescuento,
                          style: TipografiaApp.labelSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Badge Vence (esquina inferior izquierda sobre la foto)
                if (promocion.fechaFin != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.amber,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Vence: ${_formatoFechaValidezCorta(promocion.fechaFin!)}',
                            style: TipografiaApp.labelSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Contenido de la tarjeta
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
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Fila Servicios
                  Row(
                    children: [
                      Icon(
                        Icons.content_cut_rounded,
                        size: 14,
                        color: ColoresApp.primario,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          promocion.esCombo
                              ? 'Combo: ${promocion.serviciosIds.length} servicios incluidos'
                              : (promocion.serviciosIds.isNotEmpty
                                  ? 'Válido para servicios seleccionados'
                                  : 'Válido para todo el catálogo'),
                          style: TipografiaApp.bodySm.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Descripción breve si existe
                  if (promocion.descripcion != null &&
                      promocion.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      promocion.descripcion!,
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Botón VER DETALLES / RECLAMAR
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirModalDetalles(context, ref),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text(
                        'VER DETALLES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColoresApp.primario),
                        foregroundColor: ColoresApp.primario,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
          // Handle superior
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
                  // Imagen de cabecera
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
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.estadoCompletada,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          textoDescuento,
                          style: TipografiaApp.labelSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Título
                  Text(
                    promocion.titulo,
                    style: TipografiaApp.headlineSm.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
                  const SizedBox(height: 10),
                  if (serviciosIncluidos.isNotEmpty)
                    ...serviciosIncluidos.map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.content_cut_rounded,
                              color: ColoresApp.primario,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.nombre ?? 'Servicio',
                                style: TipografiaApp.bodyMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Bs. ${s.precio.toStringAsFixed(2)}',
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aplica para cualquier servicio del catálogo.',
                              style: TipografiaApp.bodyMd.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Fecha de Validez Completa
                  if (promocion.fechaFin != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VÁLIDO HASTA:',
                              style: TipografiaApp.labelSm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _formatoFechaValidezCompleta(
                                promocion.fechaFin!.toLocal(),
                              ),
                              style: TipografiaApp.bodyMd.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Botón RECLAMAR OFERTA
                  ElevatedButton.icon(
                    onPressed: onReservar,
                    icon: const Icon(Icons.local_offer_rounded, size: 22),
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
                      minimumSize: const Size.fromHeight(54),
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
