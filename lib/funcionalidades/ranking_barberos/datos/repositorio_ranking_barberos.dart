import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_insignia_ranking_barbero.dart';

abstract class RepositorioRankingBarberos {
  Future<List<ModeloInsigniaRankingBarbero>> obtenerInsignias();
}

class RepositorioRankingBarberosSupabase implements RepositorioRankingBarberos {
  RepositorioRankingBarberosSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

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
}

final repositorioRankingBarberosProvider = Provider<RepositorioRankingBarberos>(
  (ref) => RepositorioRankingBarberosSupabase(),
);
