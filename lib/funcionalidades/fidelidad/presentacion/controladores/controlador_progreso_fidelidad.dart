import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_programas_fidelidad.dart';
import '../../dominio/modelo_progreso_fidelidad.dart';

class ControladorProgresoFidelidad
    extends AsyncNotifier<List<ModeloProgresoFidelidad>> {
  @override
  FutureOr<List<ModeloProgresoFidelidad>> build() async {
    return ref
        .read(repositorioProgramasFidelidadProvider)
        .obtenerProgresoCliente();
  }

  Future<void> reclamarPremio(String programaId) async {
    await ref.read(repositorioProgramasFidelidadProvider).reclamarPremio(
      programaId,
    );
    ref.invalidateSelf();
    await future;
  }
}

final controladorProgresoFidelidadProvider =
    AsyncNotifierProvider<
      ControladorProgresoFidelidad,
      List<ModeloProgresoFidelidad>
    >(() {
      return ControladorProgresoFidelidad();
    });
