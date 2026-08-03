import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_inventario.dart';
import '../../dominio/modelo_reporte_insumo.dart';

class ControladorBandejaReportes
    extends AsyncNotifier<List<ModeloReporteInsumo>> {
  @override
  FutureOr<List<ModeloReporteInsumo>> build() async {
    return ref.read(repositorioInventarioProvider).obtenerBandejaReportes();
  }

  Future<void> revisar({
    required String reporteId,
    required bool aprobar,
  }) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloReporteInsumo>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioInventarioProvider)
          .revisarReporte(reporteId: reporteId, aprobar: aprobar);
      return listaAnterior.where((r) => r.id != reporteId).toList();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorBandejaReportesProvider =
    AsyncNotifierProvider<
      ControladorBandejaReportes,
      List<ModeloReporteInsumo>
    >(ControladorBandejaReportes.new);
