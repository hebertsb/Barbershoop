import 'modelo_programa_ranking_barberos.dart';

/// Elige qué programa mostrar en el podio del barbero: el activo con
/// [ModeloProgramaRankingBarberos.fechaInicio] más reciente si hay alguno,
/// o si no hay ninguno activo, el cerrado con `fechaFin` más reciente.
/// `null` si la sucursal no tiene ningún programa.
ModeloProgramaRankingBarberos? elegirProgramaRankingParaMostrar(
  List<ModeloProgramaRankingBarberos> programas,
) {
  if (programas.isEmpty) return null;

  final activos = programas.where((p) => p.estado == 'activo').toList()
    ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
  if (activos.isNotEmpty) return activos.first;

  final cerrados = programas.where((p) => p.estado == 'cerrado').toList()
    ..sort((a, b) => b.fechaFin.compareTo(a.fechaFin));
  if (cerrados.isNotEmpty) return cerrados.first;

  return null;
}