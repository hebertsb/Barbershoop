import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelo_secretaria.dart';
import '../../dominio/modelo_sucursal.dart';
import '../componentes/formulario_secretaria.dart';
import '../controladores/controlador_secretarias.dart';
import '../controladores/controlador_sucursales.dart';

class PantallaGestionSecretarias extends ConsumerWidget {
  const PantallaGestionSecretarias({super.key});

  String _obtenerNombreSucursal(
    String? sucursalId,
    List<ModeloSucursal> sucursales,
  ) {
    if (sucursalId == null) return 'Sin asignación';
    final candidatos = sucursales.where((s) => s.id == sucursalId).toList();
    return candidatos.isEmpty ? 'Sucursal desconocida' : candidatos.first.nombre;
  }

  Future<void> _confirmarRevocar(
    BuildContext context,
    WidgetRef ref,
    ModeloSecretaria secretaria,
  ) async {
    final nombre = secretaria.nombre ?? secretaria.email ?? 'esta secretaria';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar acceso'),
        content: Text(
          '¿Quitarle el acceso a $nombre? Va a dejar de poder entrar como '
          'secretaria hasta que la vuelvas a invitar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar acceso'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    try {
      await ref
          .read(controladorSecretariasProvider.notifier)
          .revocarSecretaria(secretaria.perfilId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final secretariasState = ref.watch(controladorSecretariasProvider);
    final sucursales = sucursalesState.value ?? <ModeloSucursal>[];

    ref.listen(controladorSecretariasProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Secretarias')),
      body: secretariasState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (secretarias) {
          if (secretarias.isEmpty) {
            return Center(
              child: Text(
                'Todavía no invitaste a ninguna secretaria.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: secretarias.length,
            itemBuilder: (context, index) {
              final secretaria = secretarias[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.badge)),
                  title: Text(secretaria.nombre ?? 'Sin nombre'),
                  subtitle: Text(
                    '${secretaria.email ?? 'Sin correo'}\n'
                    'Sucursal: ${_obtenerNombreSucursal(secretaria.sucursalId, sucursales)}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove_outlined),
                    tooltip: 'Quitar acceso',
                    onPressed: () =>
                        _confirmarRevocar(context, ref, secretaria),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
            builder: (context) => FormularioSecretaria(
              sucursales: sucursales,
              alGuardar: (email, sucursalId) {
                return ref
                    .read(controladorSecretariasProvider.notifier)
                    .invitarSecretaria(email: email, sucursalId: sucursalId);
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
