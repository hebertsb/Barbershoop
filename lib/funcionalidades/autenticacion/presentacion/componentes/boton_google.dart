import 'package:flutter/material.dart';

class BotonGoogle extends StatelessWidget {
  const BotonGoogle({super.key, required this.cargando, required this.alPresionar});

  final bool cargando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: cargando ? null : alPresionar,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Continuar con Google'),
      ),
    );
  }
}
