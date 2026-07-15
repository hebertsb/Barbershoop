import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/formulario_servicio.dart';
import '../controladores/controlador_servicios.dart';

class PantallaGestionServicios extends ConsumerWidget {
  const PantallaGestionServicios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviciosState = ref.watch(controladorServiciosProvider);

    ref.listen(controladorServiciosProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Servicios')),
      body: serviciosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (servicios) {
          if (servicios.isEmpty) {
            return const Center(child: Text('No hay servicios registrados.'));
          }

          return ListView.builder(
            itemCount: servicios.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final servicio = servicios[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        servicio.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          servicio.activo ? 'Activo' : 'Inactivo',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor:
                            servicio.activo
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
                      if (servicio.descripcion != null)
                        Text(servicio.descripcion!),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text('${servicio.duracionMin} min'),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text('Bs. ${servicio.precio.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (context) => FormularioServicio(
                            servicio: servicio,
                            alGuardar: (nuevoServicio) {
                              return ref
                                  .read(controladorServiciosProvider.notifier)
                                  .guardarServicio(nuevoServicio);
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
                (context) => FormularioServicio(
                  alGuardar: (nuevoServicio) {
                    return ref
                        .read(controladorServiciosProvider.notifier)
                        .guardarServicio(nuevoServicio);
                  },
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
