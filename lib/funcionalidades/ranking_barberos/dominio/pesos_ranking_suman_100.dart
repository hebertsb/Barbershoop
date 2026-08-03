import 'modelo_insignia_ranking_barbero.dart';

/// Verifica que los 5 pesos del ranking sumen exactamente 100.
/// Acepta un margen de ±1 por redondeo de sliders.
bool pesosRankingSuman100({
  required int pesoCitas,
  required int pesoIngresos,
  required int pesoClientes,
  required int pesoPuntualidad,
  required int pesoCalificacion,
}) {
  final suma =
      pesoCitas + pesoIngresos + pesoClientes + pesoPuntualidad + pesoCalificacion;
  return (suma - 100).abs() <= 1;
}



class ResumenMedallas {
  const ResumenMedallas({this.oro = 0, this.plata = 0, this.bronce = 0});

  final int oro;
  final int plata;
  final int bronce;

  int get total => oro + plata + bronce;
}

/// Cuenta las medallas de un barbero por puesto (1 = oro, 2 = plata,
/// 3 = bronce) -- usado tanto en la vitrina del propio barbero como en el
/// resumen compacto de Gestión de Barberos.
ResumenMedallas resumenMedallasDesde(
  List<ModeloInsigniaRankingBarbero> insignias,
) {
  var oro = 0;
  var plata = 0;
  var bronce = 0;
  for (final insignia in insignias) {
    switch (insignia.puesto) {
      case 1:
        oro++;
      case 2:
        plata++;
      case 3:
        bronce++;
    }
  }
  return ResumenMedallas(oro: oro, plata: plata, bronce: bronce);
}

/// Agrupa insignias de varios barberos (ej. toda la barbería) en un mapa
/// barberoId -> [ResumenMedallas], para mostrar el resumen compacto en
/// Gestión de Barberos con una sola consulta en vez de una por tarjeta.
Map<String, ResumenMedallas> agruparMedallasPorBarbero(
  List<ModeloInsigniaRankingBarbero> insignias,
) {
  final porBarbero = <String, List<ModeloInsigniaRankingBarbero>>{};
  for (final insignia in insignias) {
    porBarbero.putIfAbsent(insignia.barberoId, () => []).add(insignia);
  }
  return porBarbero.map(
    (id, lista) => MapEntry(id, resumenMedallasDesde(lista)),
  );
}