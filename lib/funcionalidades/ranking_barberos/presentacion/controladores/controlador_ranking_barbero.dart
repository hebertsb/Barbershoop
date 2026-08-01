import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ranking_barberos.dart';
import '../../dominio/elegir_programa_ranking_para_mostrar.dart';
import '../../dominio/modelo_insignia_ranking_barbero.dart';
import '../../dominio/modelo_programa_ranking_barberos.dart';
import '../../dominio/modelo_resultado_ranking_barbero.dart';

/// Estado combinado del ranking visto por el barbero: el programa elegido
/// para mostrar (ver [elegirProgramaRankingParaMostrar]), el podio de ese
/// programa y su vitrina histórica de insignias ganadas.
class EstadoRankingBarbero {
  const EstadoRankingBarbero({
    required this.programa,
    required this.resultados,
    required this.misInsignias,
  });

  final ModeloProgramaRankingBarberos? programa;
  final List<ModeloResultadoRankingBarbero> resultados;
  final List<ModeloInsigniaRankingBarbero> misInsignias;
}

class ControladorMiRanking extends AsyncNotifier<EstadoRankingBarbero> {
  @override
  FutureOr<EstadoRankingBarbero> build() async {
    final repo = ref.read(repositorioRankingBarberosProvider);
    final programas = await repo.obtenerProgramasDeMiSucursal();
    final elegido = elegirProgramaRankingParaMostrar(programas);
    final resultados = elegido == null
        ? <ModeloResultadoRankingBarbero>[]
        : await repo.obtenerRanking(elegido.id);
    final misInsignias = await repo.obtenerMisInsignias();
    return EstadoRankingBarbero(
      programa: elegido,
      resultados: resultados,
      misInsignias: misInsignias,
    );
  }
}

final controladorMiRankingProvider =
    AsyncNotifierProvider<ControladorMiRanking, EstadoRankingBarbero>(() {
      return ControladorMiRanking();
    });
