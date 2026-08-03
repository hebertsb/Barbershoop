import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_resumen_ingresos.dart';

/// Resumen de ingresos (hoy/mes/ao) y citas de hoy para el dashboard de
/// administracin. Es de solo lectura: no expone mtodos de escritura.
class ControladorDashboard extends AsyncNotifier<ModeloResumenIngresos> {
  @override
  FutureOr<ModeloResumenIngresos> build() async {
    return ref.read(repositorioAdministracionProvider).obtenerResumenIngresos();
  }
}

final controladorDashboardProvider =
    AsyncNotifierProvider<ControladorDashboard, ModeloResumenIngresos>(() {
      return ControladorDashboard();
    });
