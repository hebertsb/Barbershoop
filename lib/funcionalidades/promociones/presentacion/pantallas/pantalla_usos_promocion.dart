import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_promocion.dart';
import '../controladores/controlador_usos_promocion.dart';

/// Solo lectura: cuántas veces cada cliente usó (reservó con) esta
/// promoción. Visible solo para admin.
class PantallaUsosPromocion extends ConsumerWidget {
  const PantallaUsosPromocion({super.key, required this.promocion});

  final ModeloPromocion promocion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usosState = ref.watch(controladorUsosPromocionProvider(promocion.id));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Usos de "${promocion.titulo}"')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      promocion.limiteUsosPorCliente == null
                          ? 'Esta promoción no tiene límite de usos por cliente.'
                          : 'Límite: ${promocion.limiteUsosPorCliente} uso(s) por cliente.',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: usosState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (usos) {
                if (usos.isEmpty) {
                  return Center(
                    child: Text(
                      'Todavía nadie reservó con esta promoción.',
                      style: TipografiaApp.bodyMd.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final capacidadMaxima = promocion.capacidadMaxima;
                final usosTotales = usos.fold<int>(
                  0,
                  (suma, uso) => suma + uso.vecesUsada,
                );
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: usos.length + (capacidadMaxima != null ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (capacidadMaxima != null) {
                      if (index == 0) {
                        final alcanzoCapacidad =
                            usosTotales >= capacidadMaxima;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: alcanzoCapacidad
                                  ? ColoresApp.error.withValues(alpha: 0.12)
                                  : ColoresApp.primario.withValues(
                                      alpha: 0.12,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: alcanzoCapacidad
                                    ? ColoresApp.error
                                    : ColoresApp.primario,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  color: alcanzoCapacidad
                                      ? ColoresApp.error
                                      : ColoresApp.primario,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Usos totales: $usosTotales / $capacidadMaxima',
                                    style: TipografiaApp.bodyMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: alcanzoCapacidad
                                          ? ColoresApp.error
                                          : ColoresApp.primario,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      index -= 1;
                    }
                    final uso = usos[index];
                    final alcanzoLimite =
                        promocion.limiteUsosPorCliente != null &&
                        uso.vecesUsada >= promocion.limiteUsosPorCliente!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        uso.clienteNombre,
                        style: TipografiaApp.bodyMd,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: alcanzoLimite
                              ? ColoresApp.error.withValues(alpha: 0.15)
                              : ColoresApp.primario.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${uso.vecesUsada} ${uso.vecesUsada == 1 ? "uso" : "usos"}',
                          style: TipografiaApp.labelSm.copyWith(
                            color: alcanzoLimite
                                ? ColoresApp.error
                                : ColoresApp.primario,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
