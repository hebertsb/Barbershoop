import '../../administracion/dominio/modelo_servicio.dart';
import '../../promociones/dominio/enum_tipo_descuento.dart';

/// Suma el precio de todos los servicios de [servicioIds] presentes en
/// [servicios] -- ids que no aparecen en la lista de servicios contribuyen 0.
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

/// Análogo a [precioBaseCombo] pero sumando `duracionMin` -- usado para
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

/// Calcula el precio final con descuento aplicado (Porcentaje o Monto Fijo).
double calcularPrecioFinalPromocion({
  required double precioOriginal,
  required TipoDescuento tipoDescuento,
  required double valorDescuento,
}) {
  if (tipoDescuento == TipoDescuento.porcentaje) {
    final porcentaje = valorDescuento.clamp(0, 100);
    final descuentoMonto = precioOriginal * (porcentaje / 100);
    final finalPrice = precioOriginal - descuentoMonto;
    return finalPrice < 0 ? 0 : finalPrice;
  } else {
    final finalPrice = precioOriginal - valorDescuento;
    return finalPrice < 0 ? 0 : finalPrice;
  }
}
