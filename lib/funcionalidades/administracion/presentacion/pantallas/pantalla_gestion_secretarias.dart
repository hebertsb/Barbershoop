import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_secretaria.dart';
import '../../dominio/modelo_sucursal.dart';
import '../componentes/formulario_secretaria.dart';
import '../controladores/controlador_secretarias.dart';
import '../controladores/controlador_sucursales.dart';

class PantallaGestionSecretarias extends ConsumerStatefulWidget {
  const PantallaGestionSecretarias({super.key});

  @override
  ConsumerState<PantallaGestionSecretarias> createState() =>
      _PantallaGestionSecretariasState();
}

class _PantallaGestionSecretariasState
    extends ConsumerState<PantallaGestionSecretarias> {
  String _busqueda = '';

  String _obtenerNombreSucursal(
    String? sucursalId,
    List<ModeloSucursal> sucursales,
  ) {
    if (sucursalId == null) return 'Sin asignación';
    final candidatos = sucursales.where((s) => s.id == sucursalId).toList();
    return candidatos.isEmpty ? 'Sucursal' : candidatos.first.nombre;
  }

  Future<void> _confirmarRevocar(ModeloSecretaria secretaria) async {
    final nombre = secretaria.nombre;
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
            child: const Text('Quitar acceso', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await ref
          .read(controladorSecretariasProvider.notifier)
          .revocarSecretaria(secretaria.perfilId ?? secretaria.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _abrirFormulario(List<ModeloSucursal> sucursales) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioSecretaria(
        sucursales: sucursales,
        alGuardar: (email, sucursalId) => ref
            .read(controladorSecretariasProvider.notifier)
            .invitarSecretaria(email: email, sucursalId: sucursalId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final secretariasState = ref.watch(controladorSecretariasProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final sucursales = sucursalesState.value ?? <ModeloSucursal>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Secretarias')),
      body: secretariasState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (secretarias) {
          final filtradas = secretarias
              .where(
                (s) =>
                    s.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                    s.email.toLowerCase().contains(_busqueda.toLowerCase()),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar secretaria por nombre o correo...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) => setState(() => _busqueda = val),
                ),
              ),
              Expanded(
                child: filtradas.isEmpty
                    ? Center(
                        child: Text(
                          'No hay secretarias registradas.',
                          style: TipografiaApp.bodyMd.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filtradas.length,
                        itemBuilder: (context, index) {
                          final sec = filtradas[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    colorScheme.surfaceContainerHigh,
                                child: Icon(
                                  Icons.badge_outlined,
                                  color: colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                sec.nombre,
                                style: TipografiaApp.bodyMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${sec.email}\n📍 ${_obtenerNombreSucursal(sec.sucursalId, sucursales)}',
                                style: TipografiaApp.bodySm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Quitar acceso',
                                onPressed: () => _confirmarRevocar(sec),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () => _abrirFormulario(sucursales),
          icon: const Icon(Icons.person_add_outlined, size: 22),
          label: const Text(
            'NUEVA SECRETARIA / INVITAR',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.primario,
            foregroundColor: colorScheme.onPrimaryContainer,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}