import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';

/// Encabezado de sección (ej. "MAÑANA" / "TARDE") dentro de la grilla de
/// horarios disponibles.
class EncabezadoSeccionHorario extends StatelessWidget {
  const EncabezadoSeccionHorario({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TipografiaApp.labelMd.copyWith(
        color: ColoresApp.primario,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}