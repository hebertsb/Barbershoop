import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ajustes.dart';

/// Texto de instrucciones mostrado al cliente en el botn "Instrucciones"
/// de su prxima cita (panel cliente). Independiente de `ModeloMarcaBarberia`
/// -- su propio controlador, su propio Form, su propio botn "Guardar",
/// mismo criterio que `ControladorToleranciaNoAsistio`.
class ControladorInstruccionesCita extends AsyncNotifier<String> {
  @override
  FutureOr<String> build() {
    return ref.read(repositorioAjustesProvider).obtenerInstruccionesCita();
  }

  Future<void> guardar(String texto) async {
    state = const AsyncLoading<String>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAjustesProvider)
          .guardarInstruccionesCita(texto);
      return texto;
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorInstruccionesCitaProvider =
    AsyncNotifierProvider<ControladorInstruccionesCita, String>(
      ControladorInstruccionesCita.new,
    );
