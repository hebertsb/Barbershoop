import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/enum_tipo_reporte_insumo.dart';
import '../../dominio/modelo_reporte_insumo.dart';

class TarjetaReporteInsumo extends StatelessWidget {
  const TarjetaReporteInsumo({
    super.key,
    required this.reporte,
    required this.onAprobar,
    required this.onRechazar,
  });

  final ModeloReporteInsumo reporte;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  Color _colorTipo() {
    switch (reporte.tipo) {
      case TipoReporteInsumo.danado:
        return ColoresApp.estadoCancelada;
      case TipoReporteInsumo.agotado:
        return ColoresApp.estadoPendiente;
      case TipoReporteInsumo.perdido:
        return Colors.purple;
      case TipoReporteInsumo.usado:
        return ColoresApp.primario;
    }
  }

  IconData _iconoTipo() {
    switch (reporte.tipo) {
      case TipoReporteInsumo.danado:
        return Icons.broken_image_outlined;
      case TipoReporteInsumo.agotado:
        return Icons.battery_alert_outlined;
      case TipoReporteInsumo.perdido:
        return Icons.help_outline_rounded;
      case TipoReporteInsumo.usado:
        return Icons.content_cut_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorBadge = _colorTipo();
    final cantStr = reporte.cantidad % 1 == 0
        ? reporte.cantidad.toInt().toString()
        : reporte.cantidad.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Tipo de reporte y fecha
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorBadge.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconoTipo(), size: 14, color: colorBadge),
                      const SizedBox(width: 4),
                      Text(
                        reporte.tipo.etiqueta.toUpperCase(),
                        style: TipografiaApp.labelSm.copyWith(
                          color: colorBadge,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formatoFechaHora(reporte.fecha.toLocal()),
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Insumo y Cantidad
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reporte.nombreInsumo,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cantidad: $cantStr',
                    style: TipografiaApp.labelSm.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Barbero que reportó
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reportado por: ',
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Text(
                  reporte.nombreBarbero,
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Descripción u observaciones
            if (reporte.descripcion != null &&
                reporte.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reporte.descripcion!,
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            // Foto si existe
            if (reporte.urlFoto != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: reporte.urlFoto!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRechazar,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.estadoCancelada,
                      side: BorderSide(color: ColoresApp.estadoCancelada),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAprobar,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.estadoCompletada,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}