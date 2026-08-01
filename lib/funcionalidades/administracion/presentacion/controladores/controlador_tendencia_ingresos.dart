import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_punto_tendencia.dart';

/// Serie de puntos (fecha, monto) para el gráfico de la tarjeta "Tendencia
/// de Ingresos" -- `family` por período ('semana'/'mes'/'anio').
class ControladorTendenciaIngresos
    extends FamilyAsyncNotifier<List<ModeloPuntoTendencia>, String> {
  @override
  FutureOr<List<ModeloPuntoTendencia>> build(String periodo) async {
    return ref
        .read(repositorioAdministracionProvider)
        .obtenerTendenciaIngresos(periodo);
  }
}

final controladorTendenciaIngresosProvider =
    AsyncNotifierProvider.family<
      ControladorTendenciaIngresos,
      List<ModeloPuntoTendencia>,
      String
    >(ControladorTendenciaIngresos.new);
