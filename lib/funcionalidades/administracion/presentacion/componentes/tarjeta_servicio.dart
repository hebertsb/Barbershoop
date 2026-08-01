import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/modelo_servicio.dart';

class TarjetaServicio extends StatelessWidget {
  const TarjetaServicio({
    super.key,
    required this.servicio,
    required this.onTap,
    this.compacto = false,
  });

  final ModeloServicio servicio;
  final VoidCallback onTap;

  /// Modo reducido para uso en `GridView` (celda de alto fijo): imagen más
  /// baja, descripción a 1 línea y sin margen propio (el grid ya aplica
  /// espaciado). En la vista Lista se deja en `false` (comportamiento actual).
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: compacto ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  height: compacto ? 100 : 140,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHigh,
                  child: servicio.urlImagen != null
                      ? CachedNetworkImage(
                          imageUrl: servicio.urlImagen!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheHeight: 280,
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.content_cut,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.content_cut,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatoMoneda(servicio.precio),
                      style: TipografiaApp.labelMd.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                if (!servicio.activo)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColoresApp.estadoCancelada.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'INACTIVO',
                        style: TipografiaApp.labelSm.copyWith(
                          color: ColoresApp.estadoCancelada,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: compacto
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    servicio.nombre,
                    maxLines: compacto ? 1 : null,
                    overflow: compacto ? TextOverflow.ellipsis : null,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (servicio.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      servicio.descripcion!,
                      maxLines: compacto ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${servicio.duracionMin} min',
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
