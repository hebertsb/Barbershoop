import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';

abstract class RepositorioAccesosAdmin {
  /// Registra un acceso a [ruta] para el admin autenticado. Fire-and-forget
  /// desde la UI: un fallo acá no debe bloquear la navegación, así que no
  /// lanza excepciones propias -- si falla, se ignora silenciosamente.
  Future<void> registrarAcceso(String ruta);

  /// Rutas más usadas por el admin en los últimos 30 días, ordenadas de
  /// mayor a menor uso.
  Future<List<String>> obtenerRutasTopAccesos({int limite = 4});
}

class RepositorioAccesosAdminSupabase implements RepositorioAccesosAdmin {
  RepositorioAccesosAdminSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<void> registrarAcceso(String ruta) async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) return;
      await _cliente.from('accesos_admin_uso').insert({
        'perfil_id': uid,
        'ruta': ruta,
      });
    } catch (_) {
      // Silencioso a propósito: no es información crítica, no debe romper
      // la navegación del admin si Supabase no responde.
    }
  }

  @override
  Future<List<String>> obtenerRutasTopAccesos({int limite = 4}) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_accesos_rapidos_top',
                params: {'p_limite': limite},
              )
              as List;
      return filas
          .map((f) => (f as Map<String, dynamic>)['ruta'] as String)
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }
}

final repositorioAccesosAdminProvider = Provider<RepositorioAccesosAdmin>((
  ref,
) {
  return RepositorioAccesosAdminSupabase();
});
