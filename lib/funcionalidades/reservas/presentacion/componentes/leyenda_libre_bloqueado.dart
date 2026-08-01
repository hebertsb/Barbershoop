import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';

/// Leyenda de colores "Libre" / "Bloqueado" mostrada sobre la grilla cuando
/// hay un barbero específico elegido (único caso con horarios bloqueados).
class LeyendaLibreBloqueado extends StatelessWidget {
  const LeyendaLibreBloqueado({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: ColoresApp.primario,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Libre',
          style: TipografiaApp.bodySm.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: colorScheme.outline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Bloqueado',
          style: TipografiaApp.bodySm.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
