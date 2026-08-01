import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_resenas.dart';
import '../../dominio/modelo_resena.dart';

class ControladorMisResenas extends AsyncNotifier<List<ModeloResena>> {
  @override
  FutureOr<List<ModeloResena>> build() {
    return ref.read(repositorioResenasProvider).obtenerMisResenas();
  }
}

final controladorMisResenasProvider =
    AsyncNotifierProvider<ControladorMisResenas, List<ModeloResena>>(() {
      return ControladorMisResenas();
    });
