import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_reportes.dart';
import '../../dominio/modelo_cita_atendida_dia.dart';
import '../../dominio/modelo_cliente_nuevo_dia.dart';

class EstadoActividadDiaria {
  const EstadoActividadDiaria({
    required this.fecha,
    this.citasAtendidas = const [],
    this.clientesNuevos = const [],
    this.cargando = true,
    this.error,
  });

  final DateTime fecha;
  final List<ModeloCitaAtendidaDia> citasAtendidas;
  final List<ModeloClienteNuevoDia> clientesNuevos;
  final bool cargando;
  final String? error;

  EstadoActividadDiaria copyWith({
    DateTime? fecha,
    List<ModeloCitaAtendidaDia>? citasAtendidas,
    List<ModeloClienteNuevoDia>? clientesNuevos,
    bool? cargando,
    String? error,
  }) {
    return EstadoActividadDiaria(
      fecha: fecha ?? this.fecha,
      citasAtendidas: citasAtendidas ?? this.citasAtendidas,
      clientesNuevos: clientesNuevos ?? this.clientesNuevos,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

/// Controla la pantalla de Actividad del Da: mantiene la fecha seleccionada
/// (default: hoy) y carga citas atendidas + clientes nuevos de ese da.
class ControladorActividadDiaria extends Notifier<EstadoActividadDiaria> {
  @override
  EstadoActividadDiaria build() {
    Future.microtask(() => cargar());
    return EstadoActividadDiaria(fecha: DateTime.now());
  }

  Future<void> cambiarFecha(DateTime fecha) async {
    state = state.copyWith(fecha: fecha, cargando: true);
    await cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final repo = ref.read(repositorioReportesProvider);
      final citasAtendidas = await repo.obtenerCitasAtendidasDia(state.fecha);
      final clientesNuevos = await repo.obtenerClientesNuevosDia(state.fecha);

      state = state.copyWith(
        citasAtendidas: citasAtendidas,
        clientesNuevos: clientesNuevos,
        cargando: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final controladorActividadDiariaProvider =
    NotifierProvider<ControladorActividadDiaria, EstadoActividadDiaria>(
      ControladorActividadDiaria.new,
    );