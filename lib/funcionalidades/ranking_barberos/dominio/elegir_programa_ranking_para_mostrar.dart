import 'modelo_programa_ranking_barberos.dart';

/// Elige qué programa de ranking mostrarle al barbero cuando hay varios:
/// prioriza el `activo` más reciente (por `fechaInicio`); si no hay ninguno
/// activo, cae al `cerrado` más reciente (por `fechaFin`). Lista vacía
/// devuelve `null`.
ModeloProgramaRankingBarberos? elegirProgramaRankingParaMostrar(
  List<ModeloProgramaRankingBarberos> programas,
) {
  if (programas.isEmpty) return null;

  final activos = programas.where((p) => p.estado == 'activo').toList();
  if (activos.isNotEmpty) {
    activos.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return activos.first;
  }

  final ordenados = [...programas]
    ..sort((a, b) => b.fechaFin.compareTo(a.fechaFin));
  return ordenados.first;
}
