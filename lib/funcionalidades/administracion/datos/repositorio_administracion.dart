import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_barbero.dart';
import '../dominio/modelo_horario_barbero.dart';
import '../dominio/modelo_servicio.dart';
import '../dominio/modelo_sucursal.dart';

abstract class RepositorioAdministracion {
  // Sucursales
  Future<List<ModeloSucursal>> obtenerSucursales();
  Future<ModeloSucursal> guardarSucursal(ModeloSucursal sucursal);

  // Servicios
  Future<List<ModeloServicio>> obtenerServicios();
  Future<ModeloServicio> guardarServicio(ModeloServicio servicio);

  // Barberos
  Future<List<ModeloBarbero>> obtenerBarberos();
  Future<void> invitarBarbero({
    required String email,
    required String sucursalId,
    required List<String> especialidades,
  });
  Future<void> actualizarEstadoBarbero(String barberoId, bool activo);

  // Horarios de Barberos
  Future<List<ModeloHorarioBarbero>> obtenerHorariosBarbero(String barberoId);
  Future<void> guardarHorariosBarbero(
    String barberoId,
    List<ModeloHorarioBarbero> horarios,
  );
}

class RepositorioAdministracionSupabase implements RepositorioAdministracion {
  RepositorioAdministracionSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  Future<String> _obtenerBarberiaId() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) {
      throw const ExcepcionPermiso('Sesión no iniciada.');
    }
    try {
      final fila =
          await _cliente
              .from('perfiles')
              .select('barberia_id')
              .eq('id', uid)
              .maybeSingle();
      final id = fila?['barberia_id'] as String?;
      if (id == null) {
        throw const ExcepcionPermiso('No tienes una barbería asignada.');
      }
      return id;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloSucursal>> obtenerSucursales() async {
    try {
      final filas = await _cliente
          .from('sucursales')
          .select()
          .order('nombre');
      return filas.map(ModeloSucursal.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloSucursal> guardarSucursal(ModeloSucursal sucursal) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final mapa = sucursal.aJson();
      mapa['barberia_id'] = barberiaId; // Garantizar multi-tenant
      if (mapa['id'] == '') mapa.remove('id'); // Dejar que la DB genere el uuid al crear

      final fila =
          await _cliente
              .from('sucursales')
              .upsert(mapa)
              .select()
              .single();
      return ModeloSucursal.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloServicio>> obtenerServicios() async {
    try {
      final filas = await _cliente
          .from('servicios')
          .select()
          .order('nombre');
      return filas.map(ModeloServicio.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloServicio> guardarServicio(ModeloServicio servicio) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final mapa = servicio.aJson();
      mapa['barberia_id'] = barberiaId; // Garantizar multi-tenant
      if (mapa['id'] == '') mapa.remove('id'); // Dejar que la DB genere el uuid al crear

      final fila =
          await _cliente
              .from('servicios')
              .upsert(mapa)
              .select()
              .single();
      return ModeloServicio.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloBarbero>> obtenerBarberos() async {
    try {
      final filas = await _cliente
          .from('barberos')
          .select('*, perfiles:perfil_id(nombre, url_foto, email)')
          .order('activo', ascending: false);
      return filas.map(ModeloBarbero.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> invitarBarbero({
    required String email,
    required String sucursalId,
    required List<String> especialidades,
  }) async {
    try {
      await _cliente.rpc(
        'invitar_barbero_por_email',
        params: {
          'email_barbero': email,
          'id_sucursal': sucursalId,
          'especialidades': especialidades,
        },
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      // El RPC SQL lanza excepciones con raise exception (código P0001)
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<void> actualizarEstadoBarbero(String barberoId, bool activo) async {
    try {
      await _cliente
          .from('barberos')
          .update({'activo': activo})
          .eq('id', barberoId);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloHorarioBarbero>> obtenerHorariosBarbero(
    String barberoId,
  ) async {
    try {
      final filas = await _cliente
          .from('horarios_barbero')
          .select()
          .eq('barbero_id', barberoId)
          .order('dia_semana')
          .order('hora_inicio');
      return filas.map(ModeloHorarioBarbero.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarHorariosBarbero(
    String barberoId,
    List<ModeloHorarioBarbero> horarios,
  ) async {
    try {
      // reemplazar_horarios_barbero hace el delete+insert dentro de una sola
      // función SQL: si el insert falla, Postgres revierte también el delete
      // (a diferencia de dos llamadas .delete()/.insert() sueltas desde el cliente).
      await _cliente.rpc(
        'reemplazar_horarios_barbero',
        params: {
          'p_barbero_id': barberoId,
          'p_horarios': horarios
              .map(
                (h) => {
                  'dia_semana': h.diaSemana,
                  'hora_inicio': h.horaInicio,
                  'hora_fin': h.horaFin,
                },
              )
              .toList(),
        },
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }
}

final repositorioAdministracionProvider = Provider<RepositorioAdministracion>((
  ref,
) {
  return RepositorioAdministracionSupabase();
});
