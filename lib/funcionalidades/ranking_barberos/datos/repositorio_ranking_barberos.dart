import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_insignia_ranking_barbero.dart';
import '../dominio/modelo_programa_ranking_barberos.dart';
import '../dominio/modelo_resultado_ranking_barbero.dart';

abstract class RepositorioRankingBarberos {
  Future<List<ModeloInsigniaRankingBarbero>> obtenerInsignias();

  /// Obtiene TODAS las insignias de la barbería (para estadísticas de admin).
  Future<List<ModeloInsigniaRankingBarbero>> obtenerTodasLasInsignias();

  // Barbero: su propia sucursal + su vitrina de insignias
  Future<List<ModeloProgramaRankingBarberos>> obtenerProgramasDeMiSucursal();
  Future<List<ModeloResultadoRankingBarbero>> obtenerRanking(String programaId);
  Future<List<ModeloInsigniaRankingBarbero>> obtenerMisInsignias();

  // Admin: gestin de programas
  Future<List<ModeloProgramaRankingBarberos>> obtenerProgramas();
  Future<ModeloProgramaRankingBarberos> guardarPrograma(
    ModeloProgramaRankingBarberos programa,
  );
  Future<void> cerrarPrograma(String programaId);
  Future<void> marcarPremioEntregado(String programaId);
}

class RepositorioRankingBarberosSupabase implements RepositorioRankingBarberos {
  RepositorioRankingBarberosSupabase({SupabaseClient? cliente})
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
  Future<List<ModeloInsigniaRankingBarbero>> obtenerInsignias() async {
    try {
      final filas = await _cliente
          .from('insignias_ranking_barberos')
          .select('*, programas_ranking_barberos(titulo)')
          .order('otorgada_en', ascending: false);
      return filas.map(ModeloInsigniaRankingBarbero.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloInsigniaRankingBarbero>> obtenerTodasLasInsignias() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filas = await _cliente
          .from('insignias_ranking_barberos')
          .select('*, programas_ranking_barberos(titulo)')
          .eq('barberia_id', barberiaId)
          .order('otorgada_en', ascending: false);
      return filas.map(ModeloInsigniaRankingBarbero.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  Future<String?> _obtenerMiSucursalId() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) return null;
    final fila = await _cliente
        .from('barberos')
        .select('sucursal_id')
        .eq('perfil_id', uid)
        .maybeSingle();
    return fila?['sucursal_id'] as String?;
  }

  @override
  Future<List<ModeloProgramaRankingBarberos>>
  obtenerProgramasDeMiSucursal() async {
    try {
      final sucursalId = await _obtenerMiSucursalId();
      if (sucursalId == null) return [];
      final filas = await _cliente
          .from('programas_ranking_barberos')
          .select()
          .eq('sucursal_id', sucursalId)
          .order('fecha_inicio', ascending: false);
      return filas.map(ModeloProgramaRankingBarberos.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloResultadoRankingBarbero>> obtenerRanking(
    String programaId,
  ) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_ranking_barberos',
                params: {'p_programa_id': programaId},
              )
              as List;
      return filas
          .map(
            (f) => ModeloResultadoRankingBarbero.desdeJson(
              f as Map<String, dynamic>,
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
  Future<List<ModeloInsigniaRankingBarbero>> obtenerMisInsignias() async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) return [];
      final barberoFila = await _cliente
          .from('barberos')
          .select('id')
          .eq('perfil_id', uid)
          .maybeSingle();
      final barberoId = barberoFila?['id'] as String?;
      if (barberoId == null) return [];
      final filas = await _cliente
          .from('insignias_ranking_barberos')
          .select('*, programas_ranking_barberos(titulo)')
          .eq('barbero_id', barberoId)
          .order('otorgada_en', ascending: false);
      return filas.map(ModeloInsigniaRankingBarbero.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloProgramaRankingBarberos>> obtenerProgramas() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filas = await _cliente
          .from('programas_ranking_barberos')
          .select()
          .eq('barberia_id', barberiaId)
          .order('fecha_inicio', ascending: false);
      return filas.map(ModeloProgramaRankingBarberos.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloProgramaRankingBarberos> guardarPrograma(
    ModeloProgramaRankingBarberos programa,
  ) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final mapa = programa.aJson();
      mapa['barberia_id'] = barberiaId;
      if (mapa['id'] == '') {
        mapa.remove('id');
      }
      final fila = await _cliente
          .from('programas_ranking_barberos')
          .upsert(mapa)
          .select()
          .single();
      return ModeloProgramaRankingBarberos.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> cerrarPrograma(String programaId) async {
    try {
      await _cliente.rpc(
        'cerrar_programa_ranking',
        params: {'p_programa_id': programaId},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<void> marcarPremioEntregado(String programaId) async {
    try {
      await _cliente.rpc(
        'marcar_premio_entregado',
        params: {'p_programa_id': programaId},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }
}

final repositorioRankingBarberosProvider = Provider<RepositorioRankingBarberos>(
  (ref) => RepositorioRankingBarberosSupabase(),
);
