import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/errores/excepciones_app.dart';
import '../../../citas/dominio/modelo_cita.dart';
import '../../datos/repositorio_reservas.dart';

import '../../../promociones/dominio/modelo_promocion.dart';

class EstadoReserva {
  const EstadoReserva({
    this.sucursalId,
    this.servicioId,
    this.barberoId,
    this.cualquieraSeleccionado = false,
    this.fechaHora,
    this.citaIdAReemplazar,
    this.fechaHoraOriginal,
    this.promocion,
  });

  final String? sucursalId;
  final String? servicioId;
  final String? barberoId;
  final bool cualquieraSeleccionado;
  final DateTime? fechaHora;
  final String? citaIdAReemplazar;
  final DateTime? fechaHoraOriginal;
  final ModeloPromocion? promocion;
}

class ControladorReserva extends Notifier<EstadoReserva> {
  @override
  EstadoReserva build() => const EstadoReserva();

  void reiniciar() {
    state = const EstadoReserva();
  }

  void seleccionarSucursal(String sucursalId) {
    state = EstadoReserva(
      sucursalId: sucursalId,
      servicioId: state.servicioId,
      barberoId: state.barberoId,
      cualquieraSeleccionado: state.cualquieraSeleccionado,
      fechaHora: state.fechaHora,
      citaIdAReemplazar: state.citaIdAReemplazar,
      fechaHoraOriginal: state.fechaHoraOriginal,
      promocion: state.promocion,
    );
  }

  void seleccionarServicio(String servicioId) {
    state = EstadoReserva(
      sucursalId: state.sucursalId,
      servicioId: servicioId,
      barberoId: state.barberoId,
      cualquieraSeleccionado: state.cualquieraSeleccionado,
      fechaHora: state.fechaHora,
      citaIdAReemplazar: state.citaIdAReemplazar,
      fechaHoraOriginal: state.fechaHoraOriginal,
      promocion: state.promocion,
    );
  }

  void seleccionarBarberoEspecifico(String barberoId) {
    state = EstadoReserva(
      sucursalId: state.sucursalId,
      servicioId: state.servicioId,
      barberoId: barberoId,
      cualquieraSeleccionado: false,
      fechaHora: state.fechaHora,
      citaIdAReemplazar: state.citaIdAReemplazar,
      fechaHoraOriginal: state.fechaHoraOriginal,
      promocion: state.promocion,
    );
  }

  void seleccionarCualquiera() {
    state = EstadoReserva(
      sucursalId: state.sucursalId,
      servicioId: state.servicioId,
      barberoId: null,
      cualquieraSeleccionado: true,
      fechaHora: state.fechaHora,
      citaIdAReemplazar: state.citaIdAReemplazar,
      fechaHoraOriginal: state.fechaHoraOriginal,
      promocion: state.promocion,
    );
  }

  void seleccionarCualquierBarbero() => seleccionarCualquiera();
  void seleccionarBarbero(String barberoId) => seleccionarBarberoEspecifico(barberoId);

  void seleccionarHorario(DateTime fechaHora) {
    state = EstadoReserva(
      sucursalId: state.sucursalId,
      servicioId: state.servicioId,
      barberoId: state.barberoId,
      cualquieraSeleccionado: state.cualquieraSeleccionado,
      fechaHora: fechaHora,
      citaIdAReemplazar: state.citaIdAReemplazar,
      fechaHoraOriginal: state.fechaHoraOriginal,
      promocion: state.promocion,
    );
  }

  void iniciarReservaConPromocion(ModeloPromocion promocion) {
    state = EstadoReserva(
      servicioId: promocion.servicioId,
      promocion: promocion,
    );
  }

  void iniciarReprogramacion({
    required String sucursalId,
    required String servicioId,
    required String citaIdAReemplazar,
    required DateTime fechaHoraOriginal,
  }) {
    state = EstadoReserva(
      sucursalId: sucursalId,
      servicioId: servicioId,
      citaIdAReemplazar: citaIdAReemplazar,
      fechaHoraOriginal: fechaHoraOriginal,
    );
  }

  Future<({ModeloCita cita, bool esReprogramacion})> confirmar() async {
    final actual = state;
    if (actual.sucursalId == null ||
        actual.servicioId == null ||
        actual.fechaHora == null) {
      throw const ExcepcionDesconocida(
        'Faltan datos para confirmar la reserva.',
      );
    }

    final repositorio = ref.read(repositorioReservasProvider);

    // Si se está reprogramando una cita existente:
    if (actual.citaIdAReemplazar != null) {
      final citaActualizada = await repositorio.reprogramarCita(
        citaId: actual.citaIdAReemplazar!,
        nuevaFechaHora: actual.fechaHora!,
      );
      return (cita: citaActualizada, esReprogramacion: true);
    }

    // Si es una reserva nueva regular:
    final cita = await repositorio.reservarCita(
      sucursalId: actual.sucursalId!,
      servicioId: actual.servicioId!,
      barberoId: actual.barberoId,
      fechaHora: actual.fechaHora!,
      promocionId: actual.promocion?.id,
    );

    return (cita: cita, esReprogramacion: false);
  }
}

final controladorReservaProvider =
    NotifierProvider<ControladorReserva, EstadoReserva>(ControladorReserva.new);
