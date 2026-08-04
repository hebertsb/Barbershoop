import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_pago.dart';

abstract class RepositorioPagos {
  /// El pago asociado a una cita (puede no existir si nunca se subi un
  /// comprobante).
  Future<ModeloPago?> obtenerPagoDeCita(String citaId);

  /// Todos los pagos `por_verificar` de la barbera del usuario actual, con
  /// el nombre del cliente y la fecha de la cita ya embebidos.
  Future<List<ModeloPago>> obtenerPagosPorVerificar();

  Future<ModeloPago> subirComprobante({
    required String citaId,
    required double monto,
    required String urlComprobante,
  });

  Future<ModeloPago> confirmarPago(String pagoId);

  Future<ModeloPago> rechazarPago(String pagoId);
}

class RepositorioPagosSupabase implements RepositorioPagos {
  RepositorioPagosSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<ModeloPago?> obtenerPagoDeCita(String citaId) async {
    try {
      final fila = await _cliente
          .from('pagos')
          .select()
          .eq('cita_id', citaId)
          .maybeSingle();
      return fila == null ? null : ModeloPago.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloPago>> obtenerPagosPorVerificar() async {
    try {
      final filas = await _cliente
          .from('pagos')
          .select(
            '*, citas:cita_id(fecha_hora, perfiles:cliente_id(nombre, telefono))',
          )
          .eq('estado', 'por_verificar')
          .order('fecha');
      return filas.map(ModeloPago.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloPago> subirComprobante({
    required String citaId,
    required double monto,
    required String urlComprobante,
  }) async {
    try {
      final fila =
          await _cliente.rpc(
                'subir_comprobante_pago',
                params: {
                  'p_cita_id': citaId,
                  'p_monto': monto,
                  'p_url_comprobante': urlComprobante,
                },
              )
              as Map<String, dynamic>;
      return ModeloPago.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } catch (e) {
      try {
        final uid = _cliente.auth.currentUser?.id;
        final res = await _cliente.from('pagos').upsert({
          'cita_id': citaId,
          'monto': monto,
          'url_comprobante': urlComprobante,
          'estado': 'por_verificar',
          if (uid != null) 'cliente_id': uid,
        }).select().single();
        return ModeloPago.desdeJson(res);
      } on SocketException {
        throw const ExcepcionRed();
      } on PostgrestException catch (err) {
        throw ExcepcionPermiso(err.message);
      } catch (err) {
        throw ExcepcionDesconocida(err.toString());
      }
    }
  }

  @override
  Future<ModeloPago> confirmarPago(String pagoId) async {
    try {
      final fila =
          await _cliente.rpc('confirmar_pago', params: {'p_pago_id': pagoId})
              as Map<String, dynamic>;
      return ModeloPago.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloPago> rechazarPago(String pagoId) async {
    try {
      final fila =
          await _cliente.rpc('rechazar_pago', params: {'p_pago_id': pagoId})
              as Map<String, dynamic>;
      return ModeloPago.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }
}

final repositorioPagosProvider = Provider<RepositorioPagos>((ref) {
  return RepositorioPagosSupabase();
});
