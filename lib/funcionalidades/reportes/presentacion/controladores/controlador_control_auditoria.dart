import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_reportes.dart';
import '../../dominio/enum_filtro_periodo.dart';
import '../../dominio/modelo_actividad_usuario.dart';
import '../../dominio/modelo_cita_sin_pago.dart';
import '../../dominio/modelo_ingreso_por_metodo.dart';
import '../../dominio/modelo_tasa_ausentismo_barbero.dart';

class EstadoControlAuditoria {
  const EstadoControlAuditoria({
    this.filtro = FiltroPeriodo.esteMes,
    this.fechaInicioCustom,
    this.fechaFinCustom,
    this.citasSinPago = const [],
    this.ingresosPorMetodo = const [],
    this.tasaAusentismo = const [],
    this.actividadUsuarios = const [],
    this.cargando = true,
    this.error,
  });

  final FiltroPeriodo filtro;
  final DateTime? fechaInicioCustom;
  final DateTime? fechaFinCustom;
  final List<ModeloCitaSinPago> citasSinPago;
  final List<ModeloIngresoPorMetodo> ingresosPorMetodo;
  final List<ModeloTasaAusentismoBarbero> tasaAusentismo;
  final List<ModeloActividadUsuario> actividadUsuarios;
  final bool cargando;
  final String? error;

  EstadoControlAuditoria copyWith({
    FiltroPeriodo? filtro,
    DateTime? fechaInicioCustom,
    DateTime? fechaFinCustom,
    List<ModeloCitaSinPago>? citasSinPago,
    List<ModeloIngresoPorMetodo>? ingresosPorMetodo,
    List<ModeloTasaAusentismoBarbero>? tasaAusentismo,
    List<ModeloActividadUsuario>? actividadUsuarios,
    bool? cargando,
    String? error,
  }) {
    return EstadoControlAuditoria(
      filtro: filtro ?? this.filtro,
      fechaInicioCustom: fechaInicioCustom ?? this.fechaInicioCustom,
      fechaFinCustom: fechaFinCustom ?? this.fechaFinCustom,
      citasSinPago: citasSinPago ?? this.citasSinPago,
      ingresosPorMetodo: ingresosPorMetodo ?? this.ingresosPorMetodo,
      tasaAusentismo: tasaAusentismo ?? this.tasaAusentismo,
      actividadUsuarios: actividadUsuarios ?? this.actividadUsuarios,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class ControladorControlAuditoria extends Notifier<EstadoControlAuditoria> {
  @override
  EstadoControlAuditoria build() {
    Future.microtask(() => cargar());
    return const EstadoControlAuditoria();
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
      final citasSinPago = await repo.obtenerCitasSinPagoCompleto(
        fechaInicio: inicio,
        fechaFin: fin,
      );
      final ingresosPorMetodo = await repo.obtenerIngresosPorMetodoPago(
        fechaInicio: inicio,
        fechaFin: fin,
      );
      final tasaAusentismo = await repo.obtenerTasaAusentismoPorBarbero(
        fechaInicio: inicio,
        fechaFin: fin,
      );
      final actividadUsuarios = await repo.obtenerActividadPorUsuario(
        fechaInicio: inicio,
        fechaFin: fin,
      );

      state = state.copyWith(
        citasSinPago: citasSinPago,
        ingresosPorMetodo: ingresosPorMetodo,
        tasaAusentismo: tasaAusentismo,
        actividadUsuarios: actividadUsuarios,
        cargando: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final controladorControlAuditoriaProvider =
    NotifierProvider<ControladorControlAuditoria, EstadoControlAuditoria>(
      ControladorControlAuditoria.new,
    );
