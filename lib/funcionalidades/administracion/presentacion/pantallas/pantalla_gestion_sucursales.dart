import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/formulario_sucursal.dart';
import '../controladores/controlador_sucursales.dart';

class PantallaGestionSucursales extends ConsumerWidget {
  const PantallaGestionSucursales({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursalesState = ref.watch(controladorSucursalesProvider);

    ref.listen(controladorSucursalesProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Sucursales')),
      body: sucursalesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (sucursales) {
          if (sucursales.isEmpty) {
            return const Center(child: Text('No hay sucursales registradas.'));
          }

          return ListView.builder(
            itemCount: sucursales.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final sucursal = sucursales[index];
              final horarioStr =
                  sucursal.horarioApertura != null &&
                          sucursal.horarioCierre != null
                      ? '${sucursal.horarioApertura!.substring(0, 5)} - ${sucursal.horarioCierre!.substring(0, 5)}'
                      : 'Sin horario';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        sucursal.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          sucursal.activo ? 'Activa' : 'Inactiva',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor:
                            sucursal.activo
                                ? Colors.green.withAlpha(40)
                                : Colors.red.withAlpha(40),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sucursal.direccion != null)
                        Text('Dirección: ${sucursal.direccion}'),
                      if (sucursal.telefono != null)
                        Text('Teléfono: ${sucursal.telefono}'),
                      Text('Horario: $horarioStr'),
                    ],
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (context) => FormularioSucursal(
                            sucursal: sucursal,
                            alGuardar: (nuevaSucursal) {
                              return ref
                                  .read(controladorSucursalesProvider.notifier)
                                  .guardarSucursal(nuevaSucursal);
                            },
                          ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder:
                (context) => FormularioSucursal(
                  alGuardar: (nuevaSucursal) {
                    return ref
                        .read(controladorSucursalesProvider.notifier)
                        .guardarSucursal(nuevaSucursal);
                  },
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
