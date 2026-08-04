import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_resena.dart';

abstract class RepositorioResenas {
  Future<void> calificarCita({
    required String citaId,
    required int calificacion,
    String? comentario,
  });

  /// `true` si la cita ya tiene una resea del cliente autenticado.
  Future<bool> citaYaTieneResena(String citaId);

  Future<List<ModeloResena>> obtenerMisResenas();
}

class RepositorioResenasSupabase implements RepositorioResenas {
  RepositorioResenasSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<void> calificarCita({
    required String citaId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) {
        throw const ExcepcionPermiso('Sesión no iniciada.');
      }

      try {
        await _cliente.rpc(
          'calificar_cita',
          params: {
            'p_cita_id': citaId,
            'p_calificacion': calificacion,
            'p_comentario': comentario,
          },
        );
      } on PostgrestException catch (_) {
        final cita = await _cliente
            .from('citas')
            .select('barberia_id, sucursal_id, barbero_id')
            .eq('id', citaId)
            .maybeSingle();

        if (cita != null) {
          await _cliente.from('resenas').insert({
            'cita_id': citaId,
            'cliente_id': uid,
            'barberia_id': cita['barberia_id'],
            'sucursal_id': cita['sucursal_id'],
            if (cita['barbero_id'] != null) 'barbero_id': cita['barbero_id'],
            'calificacion': calificacion,
            if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
          });
        }
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw ExcepcionDesconocida(e.message.isNotEmpty ? e.message : 'Error al calificar cita.');
    }
  }

  @override
  Future<bool> citaYaTieneResena(String citaId) async {
    try {
      final fila = await _cliente
          .from('resenas')
          .select('id')
          .eq('cita_id', citaId)
          .maybeSingle();
      return fila != null;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }

  @override
  Future<List<ModeloResena>> obtenerMisResenas() async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) return [];

      try {
        final filas = await _cliente.rpc('obtener_mis_resenas') as List;
        return filas
            .map((fila) => ModeloResena.desdeJson(fila as Map<String, dynamic>))
            .toList();
      } on PostgrestException catch (_) {
        final filas = await _cliente
            .from('resenas')
            .select()
            .eq('cliente_id', uid)
            .order('creado_en', ascending: false);
        return (filas as List)
            .map((fila) => ModeloResena.desdeJson(fila as Map<String, dynamic>))
            .toList();
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }
}

final repositorioResenasProvider = Provider<RepositorioResenas>((ref) {
  return RepositorioResenasSupabase();
});
