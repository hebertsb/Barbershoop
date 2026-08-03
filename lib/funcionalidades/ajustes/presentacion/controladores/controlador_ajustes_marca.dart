import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ajustes.dart';
import '../../dominio/modelo_marca_barberia.dart';

/// Ajustes de marca de la barbera (nombre, slogan, logo, color de acento).
class ControladorAjustesMarca extends AsyncNotifier<ModeloMarcaBarberia> {
  @override
  FutureOr<ModeloMarcaBarberia> build() {
    return ref.read(repositorioAjustesProvider).obtenerMarcaBarberia();
  }

  Future<void> guardar(ModeloMarcaBarberia marca) async {
    state = const AsyncLoading<ModeloMarcaBarberia>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioAjustesProvider).guardarMarcaBarberia(marca);
      return marca;
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorAjustesMarcaProvider =
    AsyncNotifierProvider<ControladorAjustesMarca, ModeloMarcaBarberia>(
      ControladorAjustesMarca.new,
    );
