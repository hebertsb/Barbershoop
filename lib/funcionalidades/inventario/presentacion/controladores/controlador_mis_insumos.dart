import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_inventario.dart';
import '../../dominio/modelo_insumo_barbero.dart';

class ControladorMisInsumos extends AsyncNotifier<List<ModeloInsumoBarbero>> {
  @override
  FutureOr<List<ModeloInsumoBarbero>> build() async {
    return ref.read(repositorioInventarioProvider).obtenerMisInsumos();
  }
}

final controladorMisInsumosProvider =
    AsyncNotifierProvider<ControladorMisInsumos, List<ModeloInsumoBarbero>>(
      ControladorMisInsumos.new,
    );
