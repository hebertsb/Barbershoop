import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/enum_tipo_descuento.dart';
import '../../dominio/modelo_promocion.dart';

/// Tarjeta de promoción para el carrusel horizontal del panel cliente.
/// Diseño idéntico al mockup: imagen oscura arriba, badge de descuento,
/// título en negrita, descripción breve y botón de acción al fondo.
class TarjetaPromocionCliente extends StatelessWidget {
  const TarjetaPromocionCliente({
    super.key,
    required this.promocion,
    required this.onReservar,
  });

  final ModeloPromocion promocion;
  final VoidCallback onReservar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textoDescuento = promocion.tipoDescuento == TipoDescuento.porcentaje
        ? '-${promocion.descuento.toStringAsFixed(0)}%'
        : '-Bs. ${promocion.descuento.toStringAsFixed(0)}';

    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        // Fondo oscuro estilo mockup
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
              // Imagen de la promoción
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
              // Degradado inferior
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
              // Badge "VÁLIDO HASTA ..."
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
                      'VÁLIDO HASTA ${_diaSemana(promocion.fechaFin!)}',
                      style: TipografiaApp.labelSm.copyWith(
                        color: ColoresApp.primario,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              // Badge descuento (esquina superior derecha)
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
                if (promocion.etiquetaServicios.isNotEmpty) ...[
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
                          promocion.etiquetaServicios,
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
                ],
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
                // Botón "RECLAMAR OFERTA" al estilo mockup
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onReservar,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColoresApp.primario),
                      foregroundColor: ColoresApp.primario,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'RECLAMAR OFERTA',
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
    );
  }

  /// Devuelve el nombre del día de la semana abreviado en español.
  String _diaSemana(DateTime fecha) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[fecha.weekday - 1];
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
