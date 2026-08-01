import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/modelo_resena.dart';

class TarjetaResena extends StatelessWidget {
  const TarjetaResena({super.key, required this.resena});

  final ModeloResena resena;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    resena.clienteNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatoFechaCorta(resena.creadoEn.toLocal()),
                  style: TipografiaApp.labelSm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= resena.calificacion ? Icons.star : Icons.star_border,
                    size: 16,
                    color: ColoresApp.primario,
                  ),
              ],
            ),
            if (resena.comentario != null) ...[
              const SizedBox(height: 8),
              Text(
                resena.comentario!,
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
