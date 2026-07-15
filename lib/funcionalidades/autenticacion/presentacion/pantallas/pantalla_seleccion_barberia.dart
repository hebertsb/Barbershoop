import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controladores/controlador_autenticacion.dart';

class PantallaSeleccionBarberia extends ConsumerWidget {
  const PantallaSeleccionBarberia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberias = ref.watch(barberiasActivasProvider);
    final asignando = ref.watch(
      controladorAutenticacionProvider.select((estado) => estado.isLoading),
    );

    ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu barbería')),
      body: barberias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(child: Text('No hay barberías disponibles todavía.'));
          }
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, indice) {
              final barberia = lista[indice];
              return ListTile(
                title: Text(barberia.nombre),
                onTap: asignando
                    ? null
                    : () => ref
                        .read(controladorAutenticacionProvider.notifier)
                        .asignarBarberia(barberia.id),
              );
            },
          );
        },
      ),
    );
  }
}
