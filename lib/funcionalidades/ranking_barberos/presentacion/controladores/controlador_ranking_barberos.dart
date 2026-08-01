import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ranking_barberos.dart';
import '../../dominio/modelo_programa_ranking_barberos.dart';

class ControladorRankingBarberos
    extends AsyncNotifier<List<ModeloProgramaRankingBarberos>> {
  @override
  FutureOr<List<ModeloProgramaRankingBarberos>> build() async {
    return ref.read(repositorioRankingBarberosProvider).obtenerProgramas();
  }

  Future<void> guardarPrograma(ModeloProgramaRankingBarberos programa) async {
    await ref
        .read(repositorioRankingBarberosProvider)
        .guardarPrograma(programa);
    ref.invalidateSelf();
    await future;
  }

  Future<void> cerrarPrograma(String programaId) async {
    await ref
        .read(repositorioRankingBarberosProvider)
        .cerrarPrograma(programaId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> marcarPremioEntregado(String programaId) async {
    await ref
        .read(repositorioRankingBarberosProvider)
        .marcarPremioEntregado(programaId);
    ref.invalidateSelf();
    await future;
  }
}

final controladorRankingBarberosProvider =
    AsyncNotifierProvider<
      ControladorRankingBarberos,
      List<ModeloProgramaRankingBarberos>
    >(() {
      return ControladorRankingBarberos();
    });
