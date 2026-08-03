import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_punto_tendencia.dart';

/// Serie de tendencia de ingresos para el gráfico del dashboard admin,
/// family por período ('semana' | 'mes' | 'anio') -- mismo patrón que
/// `ControladorCitas` (family por día).
class ControladorTendenciaIngresos
    extends
        AutoDisposeFamilyAsyncNotifier<List<ModeloPuntoTendencia>, String> {
  @override
  FutureOr<List<ModeloPuntoTendencia>> build(String arg) {
    return ref
        .read(repositorioAdministracionProvider)
        .obtenerTendenciaIngresos(arg);
  }
}

final controladorTendenciaIngresosProvider =
    AsyncNotifierProvider.autoDispose
        .family<ControladorTendenciaIngresos, List<ModeloPuntoTendencia>, String>(
          ControladorTendenciaIngresos.new,
        );