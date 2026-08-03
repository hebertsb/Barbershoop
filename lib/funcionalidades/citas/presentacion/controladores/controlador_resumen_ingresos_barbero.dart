import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_citas.dart';
import '../../dominio/modelo_resumen_ingresos_barbero.dart';

/// Resumen de ingresos propios (hoy/semana/mes) del barbero autenticado,
/// para su panel de Inicio. Solo lectura.
class ControladorResumenIngresosBarbero
    extends AsyncNotifier<ModeloResumenIngresosBarbero> {
  @override
  FutureOr<ModeloResumenIngresosBarbero> build() async {
    return ref.read(repositorioCitasProvider).obtenerResumenIngresosBarbero();
  }
}

final controladorResumenIngresosBarberoProvider =
    AsyncNotifierProvider<
      ControladorResumenIngresosBarbero,
      ModeloResumenIngresosBarbero
    >(() {
      return ControladorResumenIngresosBarbero();
    });