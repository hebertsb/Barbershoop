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

  /// `true` si la cita ya tiene una reseña del cliente autenticado.
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
      await _cliente.rpc(
        'calificar_cita',
        params: {
          'p_cita_id': citaId,
          'p_calificacion': calificacion,
          'p_comentario': comentario,
        },
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
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
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloResena>> obtenerMisResenas() async {
    try {
      final filas = await _cliente.rpc('obtener_mis_resenas') as List;
      return filas
          .map((fila) => ModeloResena.desdeJson(fila as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }
}

final repositorioResenasProvider = Provider<RepositorioResenas>((ref) {
  return RepositorioResenasSupabase();
});
