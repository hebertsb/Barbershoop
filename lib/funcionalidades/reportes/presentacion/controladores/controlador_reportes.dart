import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_reportes.dart';
import '../../dominio/enum_filtro_periodo.dart';
import '../../dominio/modelo_reporte_barbero.dart';
import '../../dominio/modelo_reporte_cliente_frecuente.dart';
import '../../dominio/modelo_reporte_resumen.dart';
import '../../dominio/modelo_reporte_servicio.dart';

class EstadoReportes {
  const EstadoReportes({
    this.filtro = FiltroPeriodo.esteMes,
    this.fechaInicioCustom,
    this.fechaFinCustom,
    this.resumen,
    this.servicios = const [],
    this.barberos = const [],
    this.clientesFrecuentes = const [],
    this.cargando = true,
    this.error,
  });

  final FiltroPeriodo filtro;
  final DateTime? fechaInicioCustom;
  final DateTime? fechaFinCustom;
  final ModeloReporteResumen? resumen;
  final List<ModeloReporteServicio> servicios;
  final List<ModeloReporteBarbero> barberos;
  final List<ModeloReporteClienteFrecuente> clientesFrecuentes;
  final bool cargando;
  final String? error;

  EstadoReportes copyWith({
    FiltroPeriodo? filtro,
    DateTime? fechaInicioCustom,
    DateTime? fechaFinCustom,
    ModeloReporteResumen? resumen,
    List<ModeloReporteServicio>? servicios,
    List<ModeloReporteBarbero>? barberos,
    List<ModeloReporteClienteFrecuente>? clientesFrecuentes,
    bool? cargando,
    String? error,
  }) {
    return EstadoReportes(
      filtro: filtro ?? this.filtro,
      fechaInicioCustom: fechaInicioCustom ?? this.fechaInicioCustom,
      fechaFinCustom: fechaFinCustom ?? this.fechaFinCustom,
      resumen: resumen ?? this.resumen,
      servicios: servicios ?? this.servicios,
      barberos: barberos ?? this.barberos,
      clientesFrecuentes: clientesFrecuentes ?? this.clientesFrecuentes,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class ControladorReportes extends Notifier<EstadoReportes> {
  @override
  EstadoReportes build() {
    Future.microtask(() => cargar());
    return const EstadoReportes();
  }

  Future<void> cambiarFiltro(
    FiltroPeriodo filtro, {
    DateTime? inicioCustom,
    DateTime? finCustom,
  }) async {
    state = state.copyWith(
      filtro: filtro,
      fechaInicioCustom: inicioCustom,
      fechaFinCustom: finCustom,
      cargando: true,
    );
    await cargar();
  }

  Future<void> cargar() async {
    final (inicio, fin) = state.filtro.obtenerRangoFechas(
      fechaInicioCustom: state.fechaInicioCustom,
      fechaFinCustom: state.fechaFinCustom,
    );

    try {
      final repo = ref.read(repositorioReportesProvider);
      final resumen = await repo.obtenerResumenDetallado(
        fechaInicio: inicio,
        fechaFin: fin,
      );
      final servicios = await repo.obtenerReportePorServicio(
        fechaInicio: inicio,
        fechaFin: fin,
      );
      final barberos = await repo.obtenerReportePorBarbero(
        fechaInicio: inicio,
        fechaFin: fin,
      );
      final clientesFrecuentes = await repo.obtenerReporteClientesFrecuentes(
        fechaInicio: inicio,
        fechaFin: fin,
      );

      state = state.copyWith(
        resumen: resumen,
        servicios: servicios,
        barberos: barberos,
        clientesFrecuentes: clientesFrecuentes,
        cargando: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final controladorReportesProvider =
    NotifierProvider<ControladorReportes, EstadoReportes>(
      ControladorReportes.new,
    );
