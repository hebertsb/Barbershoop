import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../../promociones/dominio/modelo_promocion.dart';
import '../dominio/modelo_programa_fidelidad.dart';
import '../dominio/modelo_progreso_fidelidad.dart';

abstract class RepositorioProgramasFidelidad {
  // Admin
  Future<List<ModeloProgramaFidelidad>> obtenerProgramas();
  Future<ModeloProgramaFidelidad> guardarPrograma(
    ModeloProgramaFidelidad programa,
  );
  Future<void> cambiarEstadoPrograma({
    required String programaId,
    required bool activo,
  });

  // Cliente
  Future<List<ModeloProgresoFidelidad>> obtenerProgresoCliente();
  Future<ModeloPromocion> reclamarPremio(String programaId);
}

class RepositorioProgramasFidelidadSupabase
    implements RepositorioProgramasFidelidad {
  RepositorioProgramasFidelidadSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  Future<String> _obtenerBarberiaId() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) {
      throw const ExcepcionPermiso('Sesin no iniciada.');
    }
    final fila = await _cliente
        .from('perfiles')
        .select('barberia_id')
        .eq('id', uid)
        .maybeSingle();
    final id = fila?['barberia_id'] as String?;
    if (id == null) {
      throw const ExcepcionPermiso('No tienes una barbera asignada.');
    }
    return id;
  }

  @override
  Future<List<ModeloProgramaFidelidad>> obtenerProgramas() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filas = await _cliente
          .from('programas_fidelidad')
          .select()
          .eq('barberia_id', barberiaId)
          .order('creado_en', ascending: false);
      return (filas as List)
          .map(
            (f) =>
                ModeloProgramaFidelidad.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloProgramaFidelidad> guardarPrograma(
    ModeloProgramaFidelidad programa,
  ) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final mapa = programa.aJson();
      mapa['barberia_id'] = barberiaId;
      if (mapa['id'] == '') {
        mapa.remove('id');
      }
      try {
        final fila = await _cliente
            .from('programas_fidelidad')
            .upsert(mapa)
            .select()
            .single();
        return ModeloProgramaFidelidad.desdeJson(fila);
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('column') || msg.contains('find')) {
          if (msg.contains('nombre')) mapa.remove('nombre');
          if (msg.contains('sellos_requeridos')) mapa.remove('sellos_requeridos');
          if (msg.contains('recompensa')) mapa.remove('recompensa');
          if (msg.contains('descripcion')) mapa.remove('descripcion');
          if (msg.contains('servicio_id')) mapa.remove('servicio_id');

          final fila = await _cliente
              .from('programas_fidelidad')
              .upsert(mapa)
              .select()
              .single();
          return ModeloProgramaFidelidad.desdeJson(fila);
        }
        rethrow;
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') {
        throw ExcepcionPermiso(e.message);
      }
      throw ExcepcionDesconocida(e.message.isNotEmpty ? e.message : 'Error al guardar programa de fidelidad.');
    }
  }

  @override
  Future<void> cambiarEstadoPrograma({
    required String programaId,
    required bool activo,
  }) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      await _cliente
          .from('programas_fidelidad')
          .update({'activo': activo})
          .eq('id', programaId)
          .eq('barberia_id', barberiaId);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloProgresoFidelidad>> obtenerProgresoCliente() async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) return [];
      final filas =
          await _cliente.rpc('obtener_progreso_fidelidad_cliente') as List;
      return filas
          .map(
            (f) =>
                ModeloProgresoFidelidad.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ModeloPromocion> reclamarPremio(String programaId) async {
    try {
      final fila =
          await _cliente.rpc(
                'reclamar_premio_fidelidad',
                params: {'p_programa_id': programaId},
              )
              as Map<String, dynamic>;
      return ModeloPromocion.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }
}

final repositorioProgramasFidelidadProvider =
    Provider<RepositorioProgramasFidelidad>((ref) {
      return RepositorioProgramasFidelidadSupabase();
    });
