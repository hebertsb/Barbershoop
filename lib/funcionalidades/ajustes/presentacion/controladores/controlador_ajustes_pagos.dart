import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ajustes.dart';
import '../../dominio/modelo_configuracion_pagos.dart';

class ControladorAjustesPagos extends AsyncNotifier<ModeloConfiguracionPagos> {
  @override
  FutureOr<ModeloConfiguracionPagos> build() {
    return ref.read(repositorioAjustesProvider).obtenerConfiguracionPagos();
  }

  Future<void> guardar(ModeloConfiguracionPagos config) async {
    state = const AsyncLoading<ModeloConfiguracionPagos>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAjustesProvider)
          .guardarConfiguracionPagos(config);
      return config;
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorAjustesPagosProvider =
    AsyncNotifierProvider<ControladorAjustesPagos, ModeloConfiguracionPagos>(
      ControladorAjustesPagos.new,
    );
