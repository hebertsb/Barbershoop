import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../controladores/controlador_autenticacion.dart';

class PantallaSeleccionBarberia extends ConsumerWidget {
  const PantallaSeleccionBarberia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberias = ref.watch(barberiasActivasProvider);
    final asignando = ref.watch(
      controladorAutenticacionProvider.select((estado) => estado.isLoading),
    );
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu barbería')),
      body: barberias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Text(
                'No hay barberías disponibles todavía.',
                style: TipografiaApp.bodyMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, indice) {
              final barberia = lista[indice];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Icon(Icons.storefront, color: colorScheme.primary),
                  title: Text(
                    barberia.nombre,
                    style: TipografiaApp.bodyLg.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.outline,
                  ),
                  onTap: asignando
                      ? null
                      : () => ref
                            .read(controladorAutenticacionProvider.notifier)
                            .asignarBarberia(barberia.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
