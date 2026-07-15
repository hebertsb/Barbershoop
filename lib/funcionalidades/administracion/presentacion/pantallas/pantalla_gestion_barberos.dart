import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../componentes/formulario_barbero.dart';
import '../controladores/controlador_barberos.dart';
import '../controladores/controlador_sucursales.dart';
import '../../dominio/modelo_sucursal.dart';

class PantallaGestionBarberos extends ConsumerWidget {
  const PantallaGestionBarberos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberosState = ref.watch(controladorBarberosProvider);
    // Necesitamos las sucursales para el formulario de invitación
    final sucursalesState = ref.watch(controladorSucursalesProvider);

    ref.listen(controladorBarberosProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Barberos')),
      body: barberosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (barberos) {
          if (barberos.isEmpty) {
            return const Center(child: Text('No hay barberos registrados.'));
          }

          return ListView.builder(
            itemCount: barberos.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final barbero = barberos[index];
              final sucursalNombre = sucursalesState.maybeWhen(
                data:
                    (lista) => lista
                        .firstWhere(
                          (s) => s.id == barbero.sucursalId,
                          orElse:
                              () => ModeloSucursal(
                                id: '',
                                barberiaId: '',
                                nombre: 'Desconocida',
                                activo: false,
                              ),
                        )
                        .nombre,
                orElse: () => 'Cargando...',
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          barbero.urlFotoPerfil != null
                              ? NetworkImage(barbero.urlFotoPerfil!)
                              : null,
                      child:
                          barbero.urlFotoPerfil == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(
                      barbero.nombrePerfil ?? 'Sin Nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sucursal: $sucursalNombre'),
                        if (barbero.emailPerfil != null)
                          Text('Email: ${barbero.emailPerfil}'),
                        if (barbero.especialidades.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              children:
                                  barbero.especialidades.map((esp) {
                                    return Chip(
                                      label: Text(
                                        esp,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.indigo),
                          tooltip: 'Configurar horarios',
                          onPressed: () {
                            context.push(
                              '/administracion/barberos/${barbero.id}/horarios',
                              extra: barbero, // Pasar el barbero como extra para usar su nombre
                            );
                          },
                        ),
                        Switch(
                          value: barbero.activo,
                          onChanged: (val) {
                            ref
                                .read(controladorBarberosProvider.notifier)
                                .actualizarEstadoBarbero(barbero.id, val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Validar sucursales antes de invitar
          final sucursales = sucursalesState.value ?? [];
          final activas = sucursales.where((s) => s.activo).toList();

          if (activas.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Debes registrar y activar al menos una sucursal primero.',
                ),
              ),
            );
            return;
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder:
                (context) => FormularioBarbero(
                  sucursales: sucursales,
                  alGuardar: (email, sucursalId, especialidades) {
                    return ref
                        .read(controladorBarberosProvider.notifier)
                        .invitarBarbero(
                          email: email,
                          sucursalId: sucursalId,
                          especialidades: especialidades,
                        );
                  },
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
