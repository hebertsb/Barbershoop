import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_promocion.dart';
import '../dominio/modelo_uso_promocion.dart';

abstract class RepositorioPromociones {
  Future<List<ModeloPromocion>> obtenerPromocionesActivas();
  Future<List<ModeloPromocion>> obtenerTodasLasPromociones();
  Future<ModeloPromocion> guardarPromocion(ModeloPromocion promocion);
  Future<void> cambiarEstadoPromocion({
    required String promocionId,
    required bool activo,
  });
  Future<void> eliminarPromocion(String promocionId);

  /// Solo admin: cuntas veces cada cliente us (reserv con) esta
  /// promocin especfica. Va `obtener_usos_promocion_por_cliente` (0043).
  Future<List<ModeloUsoPromocion>> obtenerUsosPromocionPorCliente(
    String promocionId,
  );
}

class RepositorioPromocionesSupabase implements RepositorioPromociones {
  RepositorioPromocionesSupabase({SupabaseClient? cliente})
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
  Future<List<ModeloPromocion>> obtenerPromocionesActivas() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final filas = await _cliente
          .from('promociones')
          .select('*, servicios:servicio_id(nombre)')
          .eq('barberia_id', barberiaId)
          .eq('activo', true)
          .or('fecha_inicio.is.null,fecha_inicio.lte.$hoy')
          .or('fecha_fin.is.null,fecha_fin.gte.$hoy')
          .order('creado_en', ascending: false);
      return (filas as List)
          .map((f) => ModeloPromocion.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloPromocion>> obtenerTodasLasPromociones() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filas = await _cliente
          .from('promociones')
          .select('*, servicios:servicio_id(nombre)')
          .eq('barberia_id', barberiaId)
          .order('creado_en', ascending: false);
      return (filas as List)
          .map((f) => ModeloPromocion.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloPromocion> guardarPromocion(ModeloPromocion promocion) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final mapa = promocion.aJson();
      mapa['barberia_id'] = barberiaId;
      if (mapa['id'] == '' || mapa['id'] == null) {
        mapa.remove('id');
      }

      try {
        final fila = await _cliente
            .from('promociones')
            .upsert(mapa)
            .select('*, servicios:servicio_id(nombre)')
            .single();
        return ModeloPromocion.desdeJson(fila);
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains("column") || msg.contains("find")) {
          if (msg.contains("activo")) mapa.remove('activo');
          if (msg.contains("activa")) mapa.remove('activa');
          if (msg.contains("foto_url")) mapa.remove('foto_url');
          if (msg.contains("imagen")) mapa.remove('imagen');
          if (msg.contains("descuento")) mapa.remove('descuento');
          if (msg.contains("valor_descuento")) mapa.remove('valor_descuento');
          if (msg.contains("sucursal_id")) mapa.remove('sucursal_id');

          final fila = await _cliente
              .from('promociones')
              .upsert(mapa)
              .select('*, servicios:servicio_id(nombre)')
              .single();
          return ModeloPromocion.desdeJson(fila);
        }
        rethrow;
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw ExcepcionDesconocida(e.message);
    } catch (e) {
      throw ExcepcionDesconocida(e.toString());
    }
  }

  @override
  Future<void> cambiarEstadoPromocion({
    required String promocionId,
    required bool activo,
  }) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      try {
        await _cliente
            .from('promociones')
            .update({'activo': activo, 'activa': activo})
            .eq('id', promocionId)
            .eq('barberia_id', barberiaId);
      } on PostgrestException catch (e) {
        if (e.message.contains('activo')) {
          await _cliente
              .from('promociones')
              .update({'activa': activo})
              .eq('id', promocionId)
              .eq('barberia_id', barberiaId);
        } else {
          await _cliente
              .from('promociones')
              .update({'activo': activo})
              .eq('id', promocionId)
              .eq('barberia_id', barberiaId);
        }
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }

  @override
  Future<void> eliminarPromocion(String promocionId) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      await _cliente
          .from('promociones')
          .delete()
          .eq('id', promocionId)
          .eq('barberia_id', barberiaId);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloUsoPromocion>> obtenerUsosPromocionPorCliente(
    String promocionId,
  ) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_usos_promocion_por_cliente',
                params: {'p_promocion_id': promocionId},
              )
              as List;
      return filas
          .map((f) => ModeloUsoPromocion.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }
}

final repositorioPromocionesProvider = Provider<RepositorioPromociones>((ref) {
  return RepositorioPromocionesSupabase();
});
