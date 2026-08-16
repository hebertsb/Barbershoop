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
    String? citaExcluir,
  });

  Future<List<ModeloSlotGrilla>> obtenerGrillaHorarios({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    required String barberoId,
    String? promocionId,
    String? citaExcluir,
  });

  Future<ModeloCita> reservarCita({
    required String sucursalId,
    required String servicioId,
    String? barberoId,
    required DateTime fechaHora,
    String? promocionId,
  });

  Future<void> cancelarCita(String citaId);

  Future<ModeloCita> reprogramarCita({
    required String citaId,
    required DateTime nuevaFechaHora,
  });
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
    String? citaExcluir,
  }) async {
    try {
      try {
        await _cliente.rpc('cancelar_citas_pago_vencido');
      } catch (_) {}

      final filas =
          await _cliente.rpc(
                'obtener_horarios_disponibles',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_fecha': fecha.toIso8601String().split('T').first,
                  'p_barbero_id': barberoId,
                  'p_promocion_id': promocionId,
                  if (citaExcluir != null && citaExcluir.isNotEmpty)
                    'p_cita_excluir': citaExcluir,
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
    String? citaExcluir,
  }) async {
    try {
      try {
        await _cliente.rpc('cancelar_citas_pago_vencido');
      } catch (_) {}

      final filas =
          await _cliente.rpc(
                'obtener_grilla_horarios',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_fecha': fecha.toIso8601String().split('T').first,
                  'p_barbero_id': barberoId,
                  'p_promocion_id': promocionId,
                  if (citaExcluir != null && citaExcluir.isNotEmpty)
                    'p_cita_excluir': citaExcluir,
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
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) {
        throw const ExcepcionPermiso('Sesión no iniciada.');
      }

      try {
        final fila =
            await _cliente.rpc(
                  'reservar_cita',
                  params: {
                    'p_sucursal_id': sucursalId,
                    'p_servicio_id': servicioId,
                    'p_barbero_id': barberoId,
                    'p_fecha_hora': fechaHora.toUtc().toIso8601String(),
                    'p_promocion_id': promocionId,
                  },
                )
                as Map<String, dynamic>;
        return ModeloCita.desdeJson(fila);
      } on PostgrestException catch (_) {
        final sucursal = await _cliente
            .from('sucursales')
            .select('barberia_id')
            .eq('id', sucursalId)
            .maybeSingle();

        final servicio = await _cliente
            .from('servicios')
            .select('precio')
            .eq('id', servicioId)
            .maybeSingle();

        final barberiaId = sucursal?['barberia_id'] as String? ?? '';
        final precio = (servicio?['precio'] as num?)?.toDouble() ?? 0.0;

        final insertMap = <String, dynamic>{
          'barberia_id': barberiaId,
          'sucursal_id': sucursalId,
          'servicio_id': servicioId,
          'cliente_id': uid,
          if (barberoId != null && barberoId.isNotEmpty) 'barbero_id': barberoId,
          'fecha_hora': fechaHora.toUtc().toIso8601String(),
          'precio_cobrado': precio,
          'estado': 'pendiente',
          if (promocionId != null && promocionId.isNotEmpty) 'promocion_id': promocionId,
        };

        final fila = await _cliente
            .from('citas')
            .insert(insertMap)
            .select()
            .single();

        return ModeloCita.desdeJson(fila);
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    } catch (e) {
      throw ExcepcionDesconocida(e.toString());
    }
  }

  @override
  Future<void> cancelarCita(String citaId) async {
    try {
      try {
        await _cliente.rpc(
          'cancelar_cita_cliente',
          params: {'p_cita_id': citaId},
        );
      } on PostgrestException catch (e) {
        final uid = _cliente.auth.currentUser?.id;
        if (uid != null) {
          await _cliente
              .from('citas')
              .update({
                'estado': 'cancelada',
                'cancelado_por': uid,
              })
              .eq('id', citaId)
              .eq('cliente_id', uid);
          return;
        }
        throw ExcepcionPermiso(e.message);
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloCita> reprogramarCita({
    required String citaId,
    required DateTime nuevaFechaHora,
  }) async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) {
        throw const ExcepcionPermiso('Sesión no iniciada.');
      }

      final fila = await _cliente
          .from('citas')
          .update({
            'fecha_hora': nuevaFechaHora.toUtc().toIso8601String(),
          })
          .eq('id', citaId)
          .select()
          .single();

      return ModeloCita.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    } catch (e) {
      throw ExcepcionDesconocida(e.toString());
    }
  }
}

final repositorioReservasProvider = Provider<RepositorioReservas>((ref) {
  return RepositorioReservasSupabase();
});
