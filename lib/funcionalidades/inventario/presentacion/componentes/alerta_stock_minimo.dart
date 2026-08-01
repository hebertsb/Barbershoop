import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_insumo.dart';

/// Banner compacto con los insumos bajo el mínimo. `null`/lista vacía no
/// dibuja nada (el llamador decide si mostrarlo).
class AlertaStockMinimo extends StatelessWidget {
  const AlertaStockMinimo({super.key, required this.insumos});

  final List<ModeloInsumo> insumos;

  @override
  Widget build(BuildContext context) {
    if (insumos.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.estadoCancelada.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: ColoresApp.estadoCancelada, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: ColoresApp.estadoCancelada,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${insumos.length} insumo${insumos.length == 1 ? '' : 's'} bajo el mínimo',
                style: TipografiaApp.labelMd.copyWith(
                  color: ColoresApp.estadoCancelada,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insumos.map((i) => '${i.nombre} (${i.stock})').join(' · '),
            style: TipografiaApp.bodySm.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
