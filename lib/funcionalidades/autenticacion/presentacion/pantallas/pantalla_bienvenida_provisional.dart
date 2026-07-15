import 'package:flutter/material.dart';

import '../../dominio/enum_rol_usuario.dart';

class PantallaBienvenidaProvisional extends StatelessWidget {
  const PantallaBienvenidaProvisional({super.key, required this.rol, required this.nombre});

  final RolUsuario rol;
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Hola${nombre != null ? ', $nombre' : ''}, eres ${rol.name}'),
      ),
    );
  }
}
