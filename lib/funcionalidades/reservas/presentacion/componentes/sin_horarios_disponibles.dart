import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';

/// Estado vaco mostrado cuando no hay horarios libres para el da elegido.
class SinHorariosDisponibles extends StatelessWidget {
  const SinHorariosDisponibles({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay horarios libres ese da. Prueba seleccionando otra fecha.',
              textAlign: TextAlign.center,
              style: TipografiaApp.bodyMd.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
