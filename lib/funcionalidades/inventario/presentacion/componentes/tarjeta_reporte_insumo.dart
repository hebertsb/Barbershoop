import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
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
        return ColoresApp.contorno;
      case TipoReporteInsumo.usado:
        return ColoresApp.primario;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _colorTipo().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    reporte.tipo.etiqueta,
                    style: TipografiaApp.labelSm.copyWith(color: _colorTipo()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${reporte.nombreInsumo}  ${reporte.cantidad}',
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Reportado por ${reporte.nombreBarbero}',
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (reporte.descripcion != null) ...[
              const SizedBox(height: 4),
              Text(
                reporte.descripcion!,
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (reporte.urlFoto != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: reporte.urlFoto!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRechazar,
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAprobar,
                    child: const Text('Aprobar'),
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