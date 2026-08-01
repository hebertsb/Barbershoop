import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_programas_fidelidad.dart';
import '../../dominio/modelo_programa_fidelidad.dart';

class ControladorProgramasFidelidad
    extends AsyncNotifier<List<ModeloProgramaFidelidad>> {
  @override
  FutureOr<List<ModeloProgramaFidelidad>> build() async {
    return ref.read(repositorioProgramasFidelidadProvider).obtenerProgramas();
  }

  Future<void> guardarPrograma(ModeloProgramaFidelidad programa) async {
    await ref
        .read(repositorioProgramasFidelidadProvider)
        .guardarPrograma(programa);
    ref.invalidateSelf();
    await future;
  }

  Future<void> cambiarEstadoPrograma(String programaId, bool activo) async {
    await ref
        .read(repositorioProgramasFidelidadProvider)
        .cambiarEstadoPrograma(programaId: programaId, activo: activo);
    ref.invalidateSelf();
    await future;
  }
}

final controladorProgramasFidelidadProvider =
    AsyncNotifierProvider<
      ControladorProgramasFidelidad,
      List<ModeloProgramaFidelidad>
    >(() {
      return ControladorProgramasFidelidad();
    });
