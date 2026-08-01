import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../../citas/dominio/modelo_cita.dart';
import '../dominio/modelo_horario_disponible.dart';
import '../dominio/modelo_slot_grilla.dart';

abstract class RepositorioReservas {
  Future<List<ModeloHorarioDisponible>> obtenerHorariosDisponibles({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    String? barberoId,
    String? promocionId,
  });

  Future<List<ModeloSlotGrilla>> obtenerGrillaHorarios({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    required String barberoId,
    String? promocionId,
  });

  Future<ModeloCita> reservarCita({
    required String sucursalId,
    required String servicioId,
    String? barberoId,
    required DateTime fechaHora,
    String? promocionId,
  });

  Future<void> cancelarCita(String citaId);
}

class RepositorioReservasSupabase implements RepositorioReservas {
  RepositorioReservasSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<List<ModeloHorarioDisponible>> obtenerHorariosDisponibles({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    String? barberoId,
    String? promocionId,
  }) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_horarios_disponibles',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_fecha': fecha.toIso8601String().split('T').first,
                  'p_barbero_id': barberoId,
                  'p_promocion_id': promocionId,
                },
              )
              as List;
      return filas
          .map(
            (fila) => ModeloHorarioDisponible.desdeJson(
              fila as Map<String, dynamic>,
            ),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloSlotGrilla>> obtenerGrillaHorarios({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    required String barberoId,
    String? promocionId,
  }) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_grilla_horarios',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_fecha': fecha.toIso8601String().split('T').first,
                  'p_barbero_id': barberoId,
                  'p_promocion_id': promocionId,
                },
              )
              as List;
      return filas
          .map(
            (fila) => ModeloSlotGrilla.desdeJson(fila as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloCita> reservarCita({
    required String sucursalId,
    required String servicioId,
    String? barberoId,
    required DateTime fechaHora,
    String? promocionId,
  }) async {
    try {
      final fila =
          await _cliente.rpc(
                'reservar_cita',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_barbero_id': barberoId,
                  'p_fecha_hora': fechaHora.toIso8601String(),
                  'p_promocion_id': promocionId,
                },
              )
              as Map<String, dynamic>;
      return ModeloCita.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<void> cancelarCita(String citaId) async {
    try {
      await _cliente.rpc(
        'cancelar_cita_cliente',
        params: {'p_cita_id': citaId},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }
}

final repositorioReservasProvider = Provider<RepositorioReservas>((ref) {
  return RepositorioReservasSupabase();
});
