import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../../pagos/dominio/enum_metodo_pago.dart';
import '../dominio/enum_modo_cobro_caja.dart';
import '../dominio/modelo_cliente_walkin.dart';
import '../dominio/modelo_turno.dart';

abstract class RepositorioTurnos {
  Future<List<ModeloTurno>> obtenerTurnosDelDia(String sucursalId);

  Future<ModeloTurno> crearTurnoConCuenta({
    required String sucursalId,
    required String servicioId,
    required String clienteId,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  });

  Future<ModeloTurno> crearTurnoWalkin({
    required String sucursalId,
    required String servicioId,
    required String nombre,
    required String telefono,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  });

  Future<void> llamarTurno({required String turnoId, required String barberoId});

  Future<String> completarTurno({
    required String turnoId,
    double? monto,
    MetodoPago? metodo,
  });

  Future<void> cancelarTurno(String turnoId);

  Future<ModeloTurno> confirmarLlegadaCita(String citaId);

  Future<ModeloClienteWalkin?> buscarClienteWalkinPorTelefono(String telefono);

  Future<Map<String, String>?> buscarClientePorEmail(String email);

  Future<ModoCobroCaja> obtenerModoCobroCaja();
}

class RepositorioTurnosSupabase implements RepositorioTurnos {
  RepositorioTurnosSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<List<ModeloTurno>> obtenerTurnosDelDia(String sucursalId) async {
    try {
      final filas = await _cliente
          .from('turnos')
          .select()
          .eq('sucursal_id', sucursalId)
          .order('numero');
      return filas.map(ModeloTurno.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloTurno> crearTurnoConCuenta({
    required String sucursalId,
    required String servicioId,
    required String clienteId,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    try {
      final fila =
          await _cliente.rpc(
                'crear_turno',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_cliente_id': clienteId,
                  'p_monto_precobrado': montoPrecobrado,
                  'p_metodo_precobrado': metodoPrecobrado?.aTexto(),
                },
              )
              as Map<String, dynamic>;
      return ModeloTurno.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloTurno> crearTurnoWalkin({
    required String sucursalId,
    required String servicioId,
    required String nombre,
    required String telefono,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    try {
      final fila =
          await _cliente.rpc(
                'crear_turno_walkin',
                params: {
                  'p_sucursal_id': sucursalId,
                  'p_servicio_id': servicioId,
                  'p_nombre': nombre,
                  'p_telefono': telefono,
                  'p_monto_precobrado': montoPrecobrado,
                  'p_metodo_precobrado': metodoPrecobrado?.aTexto(),
                },
              )
              as Map<String, dynamic>;
      return ModeloTurno.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<void> llamarTurno({
    required String turnoId,
    required String barberoId,
  }) async {
    try {
      await _cliente.rpc(
        'llamar_turno',
        params: {'p_turno_id': turnoId, 'p_barbero_id': barberoId},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<String> completarTurno({
    required String turnoId,
    double? monto,
    MetodoPago? metodo,
  }) async {
    try {
      final resultado = await _cliente.rpc(
        'completar_turno_y_cobrar',
        params: {
          'p_turno_id': turnoId,
          'p_monto': monto,
          'p_metodo': metodo?.aTexto(),
        },
      );
      return resultado as String;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<void> cancelarTurno(String turnoId) async {
    try {
      await _cliente.rpc('cancelar_turno', params: {'p_turno_id': turnoId});
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloTurno> confirmarLlegadaCita(String citaId) async {
    try {
      final fila =
          await _cliente.rpc(
                'confirmar_llegada_cita',
                params: {'p_cita_id': citaId},
              )
              as Map<String, dynamic>;
      return ModeloTurno.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloClienteWalkin?> buscarClienteWalkinPorTelefono(
    String telefono,
  ) async {
    try {
      final fila = await _cliente
          .from('clientes_walkin')
          .select()
          .eq('telefono', telefono)
          .maybeSingle();
      if (fila == null) return null;
      return ModeloClienteWalkin.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<Map<String, String>?> buscarClientePorEmail(String email) async {
    try {
      final fila = await _cliente
          .from('perfiles')
          .select('id, nombre')
          .eq('email', email)
          .eq('rol', 'cliente')
          .maybeSingle();
      if (fila == null) return null;
      return {'id': fila['id'] as String, 'nombre': fila['nombre'] as String};
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModoCobroCaja> obtenerModoCobroCaja() async {
    try {
      final fila = await _cliente
          .from('configuraciones_barberia')
          .select('valor')
          .eq('clave', 'modo_cobro_caja')
          .maybeSingle();
      final texto = fila?['valor']?['modo'] as String?;
      return ModoCobroCaja.desdeTexto(texto ?? 'al_final');
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }
}

final repositorioTurnosProvider = Provider<RepositorioTurnos>((ref) {
  return RepositorioTurnosSupabase();
});
