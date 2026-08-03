import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../controladores/controlador_alerta_stock.dart';

/// Aviso compacto en el panel de Inicio del barbero cuando hay insumos bajo
/// el stock mnimo. Cuenta insumos de TODA la barbera (limitacin conocida
/// de [controladorAlertaStockProvider], no filtra por sucursal). No muestra
/// nada si no hay insumos bajo mnimo.
class AlertaInsumosBarbero extends ConsumerWidget {
  const AlertaInsumosBarbero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorAlertaStockProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return estado.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (cantidad) {
        if (cantidad <= 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cantidad == 1
                      ? 'Hay 1 insumo con stock bajo mnimo.'
                      : 'Hay $cantidad insumos con stock bajo mnimo.',
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
