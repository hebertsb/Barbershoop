import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/enum_rol_usuario.dart';
import '../controladores/controlador_autenticacion.dart';

class PantallaBienvenidaProvisional extends ConsumerWidget {
  const PantallaBienvenidaProvisional({super.key, required this.rol, required this.nombre});

  final RolUsuario rol;
  final String? nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(controladorAutenticacionProvider.notifier).cerrarSesion(),
          ),
        ],
      ),
      body: Center(
        child: Text('Hola${nombre != null ? ', $nombre' : ''}, eres ${rol.name}'),
      ),
    );
  }
}
