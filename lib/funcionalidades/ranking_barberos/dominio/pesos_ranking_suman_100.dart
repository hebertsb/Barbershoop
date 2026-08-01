/// Los 5 pesos ponderados del programa de ranking deben sumar exactamente
/// 100 -- mismo criterio que valida `pesos_suman_100` del lado SQL.
bool pesosRankingSuman100({
  required int pesoCitas,
  required int pesoIngresos,
  required int pesoClientes,
  required int pesoPuntualidad,
  required int pesoCalificacion,
}) {
  return pesoCitas +
          pesoIngresos +
          pesoClientes +
          pesoPuntualidad +
          pesoCalificacion ==
      100;
}
