import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../../../nucleo/utilidades/rango_fecha.dart';
import '../dominio/modelo_cita.dart';
import '../dominio/modelo_resumen_ingresos_barbero.dart';

abstract class RepositorioCitas {
  Future<List<ModeloCita>> obtenerCitasDelDia(String sucursalId);
  Future<List<ModeloCita>> obtenerMisCitas();
  Future<ModeloCita> marcarNoAsistio(String citaId);
  Future<ModeloResumenIngresosBarbero> obtenerResumenIngresosBarbero();
}

class RepositorioCitasSupabase implements RepositorioCitas {
  RepositorioCitasSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<List<ModeloCita>> obtenerCitasDelDia(String sucursalId) async {
    try {
      final rango = rangoDeHoyEnUtc(DateTime.now());
      final filas = await _cliente
          .from('citas')
          .select(
            '*, perfiles:cliente_id(nombre, telefono), '
            'clientes_walkin:cliente_walkin_id(nombre, telefono), '
            'promociones(nombres_servicios)',
          )
          .eq('sucursal_id', sucursalId)
          .gte('fecha_hora', rango.inicio.toIso8601String())
          .lt('fecha_hora', rango.fin.toIso8601String())
          .order('fecha_hora');
      return filas.map(ModeloCita.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }

  @override
  Future<List<ModeloCita>> obtenerMisCitas() async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) {
        return const [];
      }

      try {
        final ahoraUtc = DateTime.now().toUtc().toIso8601String();
        await _cliente
            .from('citas')
            .update({'estado': 'cancelada'})
            .eq('cliente_id', uid)
            .eq('estado', 'pendiente')
            .lt('fecha_hora', ahoraUtc);
      } catch (_) {}

      final filas = await _cliente
          .from('citas')
          .select('*, promociones(*)')
          .eq('cliente_id', uid)
          .order('fecha_hora', ascending: false);
      return filas.map(ModeloCita.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ModeloCita> marcarNoAsistio(String citaId) async {
    try {
      final fila =
          await _cliente.rpc(
                'marcar_cita_no_asistio',
                params: {'p_cita_id': citaId},
              )
              as Map<String, dynamic>;
      return ModeloCita.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<ModeloResumenIngresosBarbero> obtenerResumenIngresosBarbero() async {
    try {
      final filas =
          await _cliente.rpc('obtener_resumen_ingresos_barbero') as List;
      if (filas.isEmpty) {
        return ModeloResumenIngresosBarbero.desdeJson(const {
          'total_dia': 0.0,
          'total_mes': 0.0,
          'citas_completadas_mes': 0,
        });
      }
      return ModeloResumenIngresosBarbero.desdeJson(
        filas.first as Map<String, dynamic>,
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }
}

final repositorioCitasProvider = Provider<RepositorioCitas>((ref) {
  return RepositorioCitasSupabase();
});