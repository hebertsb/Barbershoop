import 'package:flutter/material.dart';

class BotonFacebook extends StatelessWidget {
  const BotonFacebook({super.key, required this.cargando, required this.alPresionar});

  final bool cargando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: cargando ? null : alPresionar,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1877F2)),
        icon: const Icon(Icons.facebook, size: 24),
        label: const Text('Continuar con Facebook'),
      ),
    );
  }
}
