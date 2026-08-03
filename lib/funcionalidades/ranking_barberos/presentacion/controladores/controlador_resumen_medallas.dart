import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ranking_barberos.dart';
import '../../dominio/resumen_medallas_barbero.dart';

/// Medallas de TODOS los barberos de la barbería, agrupadas por barbero --
/// una sola consulta para pintar el resumen compacto en todas las tarjetas
/// de Gestión de Barberos sin pedir una por tarjeta.
final controladorResumenMedallasProvider =
    FutureProvider<Map<String, ResumenMedallas>>((ref) async {
      try {
        final insignias = await ref
            .read(repositorioRankingBarberosProvider)
            .obtenerTodasLasInsignias();
        return agruparMedallasPorBarbero(insignias);
      } catch (_) {
        return <String, ResumenMedallas>{};
      }
    });