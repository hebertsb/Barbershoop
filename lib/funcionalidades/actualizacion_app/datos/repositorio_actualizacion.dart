import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_version_app.dart';

abstract class RepositorioActualizacion {
  Future<ModeloVersionApp?> obtenerUltimaVersion();
}

class RepositorioActualizacionSupabase implements RepositorioActualizacion {
  RepositorioActualizacionSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<ModeloVersionApp?> obtenerUltimaVersion() async {
    try {
      final fila = await _cliente
          .from('versiones_app')
          .select()
          .order('creado_en', ascending: false)
          .limit(1)
          .maybeSingle();
      if (fila == null) return null;
      return ModeloVersionApp.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }
}

final repositorioActualizacionProvider = Provider<RepositorioActualizacion>((
  ref,
) {
  return RepositorioActualizacionSupabase();
});
