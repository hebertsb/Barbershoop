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
    this.promocion,
  });

  final String? sucursalId;
  final String? servicioId;
  final String? barberoId;
  final bool cualquieraSeleccionado;
  final DateTime? fechaHora;
  final String? citaIdAReemplazar;
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
      promocion: state.promocion,
    );
  }

  void seleccionarHorario(DateTime fechaHora) {
    state = EstadoReserva(
      sucursalId: state.sucursalId,
      servicioId: state.servicioId,
      barberoId: state.barberoId,
      cualquieraSeleccionado: state.cualquieraSeleccionado,
      fechaHora: fechaHora,
      citaIdAReemplazar: state.citaIdAReemplazar,
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
  }) {
    state = EstadoReserva(
      sucursalId: sucursalId,
      servicioId: servicioId,
      citaIdAReemplazar: citaIdAReemplazar,
    );
  }

  Future<({ModeloCita cita, bool cancelacionAnteriorFallo})> confirmar() async {
    final actual = state;
    if (actual.sucursalId == null ||
        actual.servicioId == null ||
        actual.fechaHora == null) {
      throw const ExcepcionDesconocida(
        'Faltan datos para confirmar la reserva.',
      );
    }

    final repositorio = ref.read(repositorioReservasProvider);
    final cita = await repositorio.reservarCita(
      sucursalId: actual.sucursalId!,
      servicioId: actual.servicioId!,
      barberoId: actual.barberoId,
      fechaHora: actual.fechaHora!,
      promocionId: actual.promocion?.id,
    );

    // La cita nueva ya está creada: cancelar la vieja es "mejor esfuerzo".
    // Si falla (ej. el cliente ya no tiene conexión), NO se debe hacer
    // fallar esta llamada -- ya reservó con éxito y perder eso sería peor
    // que dejarle una cita vieja pendiente (puede cancelarla a mano desde
    // "Mis citas", o el propio local la ve duplicada y la resuelve). Se
    // reporta en el valor de retorno para que la UI pueda avisarle al
    // cliente (además de quedar logueado, por si algún día hay reporte de
    // errores en producción).
    var cancelacionAnteriorFallo = false;
    if (actual.citaIdAReemplazar != null) {
      try {
        await repositorio.cancelarCita(actual.citaIdAReemplazar!);
      } catch (e) {
        cancelacionAnteriorFallo = true;
        debugPrint(
          'No se pudo cancelar la cita reemplazada '
          '(${actual.citaIdAReemplazar}) tras reprogramar a '
          '${cita.id}: $e',
        );
      }
    }

    return (cita: cita, cancelacionAnteriorFallo: cancelacionAnteriorFallo);
  }
}

final controladorReservaProvider =
    NotifierProvider<ControladorReserva, EstadoReserva>(ControladorReserva.new);
