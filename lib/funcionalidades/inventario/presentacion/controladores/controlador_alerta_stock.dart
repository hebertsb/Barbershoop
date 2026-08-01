import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_inventario.dart';

/// Cantidad de insumos bajo stock mínimo en toda la barbería -- alerta
/// compacta del panel de Inicio del barbero.
class ControladorAlertaStock extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() async {
    return ref.read(repositorioInventarioProvider).contarInsumosBajoMinimo();
  }
}

final controladorAlertaStockProvider =
    AsyncNotifierProvider<ControladorAlertaStock, int>(
      ControladorAlertaStock.new,
    );
