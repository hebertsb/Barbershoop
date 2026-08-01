import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';

class EncabezadoSeccionHorario extends StatelessWidget {
  const EncabezadoSeccionHorario({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      texto,
      style: TipografiaApp.labelMd.copyWith(
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
