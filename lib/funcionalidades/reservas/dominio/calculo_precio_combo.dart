import '../../administracion/dominio/modelo_servicio.dart';

/// Suma el precio de todos los servicios de [servicioIds] presentes en
/// [servicios] -- ids que no aparecen en la lista de servicios contribuyen 0
/// (borrado/desactivado, o lista an no cargada).
double precioBaseCombo(List<String> servicioIds, List<ModeloServicio> servicios) {
  double total = 0;
  for (final id in servicioIds) {
    final candidatos = servicios.where((s) => s.id == id).toList();
    if (candidatos.isNotEmpty) {
      total += candidatos.first.precio;
    }
  }
  return total;
}

/// Anlogo a [precioBaseCombo] pero sumando `duracionMin` -- usado para
/// calcular el bloque total de tiempo que reserva un combo.
int duracionTotalCombo(List<String> servicioIds, List<ModeloServicio> servicios) {
  int total = 0;
  for (final id in servicioIds) {
    final candidatos = servicios.where((s) => s.id == id).toList();
    if (candidatos.isNotEmpty) {
      total += candidatos.first.duracionMin;
    }
  }
  return total;
}
