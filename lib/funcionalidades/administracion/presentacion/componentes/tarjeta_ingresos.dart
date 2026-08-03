import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';

/// Tarjeta compacta para mostrar un monto de ingresos (hoy/mes/ao) en el
/// dashboard de administracin. Pensada para usarse varias veces en fila.
class TarjetaIngresos extends StatelessWidget {
  const TarjetaIngresos({super.key, required this.titulo, required this.monto});

  final String titulo;
  final double monto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.toUpperCase(),
              style: TipografiaApp.labelSm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatoMoneda(monto),
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}