import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../controladores/controlador_mis_insumos.dart';

class PantallaMisInsumos extends ConsumerWidget {
  const PantallaMisInsumos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumosState = ref.watch(controladorMisInsumosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Insumos Asignados')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(controladorMisInsumosProvider.future),
        child: insumosState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (insumos) {
            if (insumos.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                      child: Text('Todavía no tienes insumos asignados.'),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: insumos.length,
              itemBuilder: (context, index) {
                final fila = insumos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      fila.nombreInsumo,
                      style: TipografiaApp.bodyMd.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Cantidad asignada a tu cargo',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ColoresApp.primario.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${fila.cantidadAsignada}',
                        style: TipografiaApp.headlineSm.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/mis-insumos/reportar'),
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Reportar Insumo'),
      ),
    );
  }
}