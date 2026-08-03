import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../controladores/controlador_mis_insumos.dart';

class PantallaMisInsumos extends ConsumerWidget {
  const PantallaMisInsumos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumosState = ref.watch(controladorMisInsumosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis insumos')),
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
                      child: Text('Todava no tens insumos asignados.'),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      fila.nombreInsumo,
                      style: TipografiaApp.bodyMd.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      '${fila.cantidadAsignada}',
                      style: TipografiaApp.headlineSm.copyWith(
                        color: colorScheme.onSurface,
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
        label: const Text('Reportar'),
      ),
    );
  }
}