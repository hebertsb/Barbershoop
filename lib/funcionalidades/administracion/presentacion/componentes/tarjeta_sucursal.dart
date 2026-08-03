import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_sucursal.dart';

class TarjetaSucursal extends StatelessWidget {
  const TarjetaSucursal({
    super.key,
    required this.sucursal,
    required this.onTap,
    this.compacto = false,
  });

  final ModeloSucursal sucursal;
  final VoidCallback onTap;

  /// Modo reducido para uso en `GridView` (celda de alto fijo): imagen ms
  /// baja y padding menor. En la vista Lista se deja en `false`
  /// (comportamiento actual, sin cambios). Mismo criterio que
  /// `TarjetaServicio.compacto`.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horarioStr =
        sucursal.horarioApertura != null && sucursal.horarioCierre != null
        ? '${sucursal.horarioApertura} - ${sucursal.horarioCierre}'
        : 'Sin horario registrado';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen superior centrada de lado a lado
            Stack(
              children: [
                Container(
                  height: compacto ? 100 : 140,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHigh,
                  child:
                      sucursal.urlImagen != null &&
                          sucursal.urlImagen!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: sucursal.urlImagen!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheHeight: 280,
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.storefront,
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
                            Icons.storefront,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                // Badge de estado Activa / Inactiva
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (sucursal.activo
                                  ? ColoresApp.estadoCompletada
                                  : ColoresApp.estadoCancelada)
                              .withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      sucursal.activo ? 'ACTIVA' : 'INACTIVA',
                      style: TipografiaApp.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Atributos y detalles de la sucursal debajo de la imagen
            Padding(
              padding: compacto
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sucursal.nombre,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: ColoresApp.primario,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sucursal.direccion ?? 'Direccin no especificada',
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sucursal.telefono ?? 'Sin telfono',
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          horarioStr,
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (sucursal.managerNombre != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: ColoresApp.primario,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Manager: ${sucursal.managerNombre}',
                            style: TipografiaApp.bodySm.copyWith(
                              color: ColoresApp.primario,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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