import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ranking_barberos.dart';
import '../../dominio/resumen_medallas_barbero.dart';

/// Medallas de todos los barberos de la barbería, agrupadas por
/// `barberoId` -- una sola consulta para pintar el resumen compacto en
/// cada tarjeta de `PantallaGestionBarberos`.
class ControladorResumenMedallas
    extends AsyncNotifier<Map<String, ResumenMedallas>> {
  @override
  FutureOr<Map<String, ResumenMedallas>> build() async {
    final insignias = await ref
        .read(repositorioRankingBarberosProvider)
        .obtenerInsignias();
    return agruparMedallasPorBarbero(insignias);
  }
}

final controladorResumenMedallasProvider =
    AsyncNotifierProvider<ControladorResumenMedallas, Map<String, ResumenMedallas>>(
      ControladorResumenMedallas.new,
    );
