import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../../administracion/dominio/modelo_servicio.dart';

/// Tarjeta de servicio popular para el carrusel horizontal del panel cliente.
/// Altura fija: 220px (imagen 130 + contenido 90).
class TarjetaServicioPopular extends StatelessWidget {
  const TarjetaServicioPopular({super.key, required this.servicio, this.onTap});

  final ModeloServicio servicio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen con badge de precio superpuesto
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  child: _ImagenServicio(
                    urlImagen: servicio.urlImagen,
                    colorScheme: colorScheme,
                  ),
                ),
                // Degradado inferior para legibilidad
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surfaceContainer.withValues(alpha: 0.85),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Badge del precio
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.primario,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatoMoneda(servicio.precio),
                      style: TipografiaApp.labelSm.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Contenido de texto
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    servicio.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (servicio.descripcion != null &&
                      servicio.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      servicio.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagenServicio extends StatelessWidget {
  const _ImagenServicio({required this.urlImagen, required this.colorScheme});

  final String? urlImagen;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (urlImagen == null) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.content_cut_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: urlImagen!,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.content_cut_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
