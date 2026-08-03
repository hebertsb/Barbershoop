import 'package:geolocator/geolocator.dart';
import '../../administracion/dominio/modelo_sucursal.dart';

class SucursalConDistancia {
  const SucursalConDistancia({
    required this.sucursal,
    this.distanciaMetros,
  });

  final ModeloSucursal sucursal;
  final double? distanciaMetros;
}

List<SucursalConDistancia> ordenarSucursalesPorDistancia(
  List<ModeloSucursal> sucursales,
  Position? posicionActual,
) {
  if (posicionActual == null) {
    return sucursales.map((s) => SucursalConDistancia(sucursal: s)).toList();
  }

  final conDistancia = sucursales.map((s) {
    if (s.latitud == null || s.longitud == null) {
      return SucursalConDistancia(sucursal: s);
    }
    final d = Geolocator.distanceBetween(
      posicionActual.latitude,
      posicionActual.longitude,
      s.latitud!,
      s.longitud!,
    );
    return SucursalConDistancia(sucursal: s, distanciaMetros: d);
  }).toList();

  conDistancia.sort((a, b) {
    if (a.distanciaMetros == null && b.distanciaMetros == null) return 0;
    if (a.distanciaMetros == null) return 1;
    if (b.distanciaMetros == null) return -1;
    return a.distanciaMetros!.compareTo(b.distanciaMetros!);
  });

  return conDistancia;
}
