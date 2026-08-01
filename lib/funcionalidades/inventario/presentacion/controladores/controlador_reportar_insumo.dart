import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_inventario.dart';
import '../../dominio/enum_tipo_reporte_insumo.dart';
import 'controlador_alerta_stock.dart';
import 'controlador_mis_insumos.dart';

class ControladorReportarInsumo extends Notifier<void> {
  @override
  void build() {}

  Future<void> reportar({
    required String insumoId,
    required TipoReporteInsumo tipo,
    required int cantidad,
    String? descripcion,
    String? urlFoto,
  }) async {
    await ref.read(repositorioInventarioProvider).reportarInsumo(
      insumoId: insumoId,
      tipo: tipo,
      cantidad: cantidad,
      descripcion: descripcion,
      urlFoto: urlFoto,
    );
    ref.invalidate(controladorMisInsumosProvider);
    ref.invalidate(controladorAlertaStockProvider);
  }
}

final controladorReportarInsumoProvider =
    NotifierProvider<ControladorReportarInsumo, void>(
      ControladorReportarInsumo.new,
    );
