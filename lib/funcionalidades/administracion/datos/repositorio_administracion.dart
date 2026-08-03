import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_barbero.dart';
import '../dominio/modelo_horario_barbero.dart';
import '../dominio/modelo_punto_tendencia.dart';
import '../dominio/modelo_resumen_ingresos.dart';
import '../dominio/modelo_secretaria.dart';
import '../dominio/modelo_servicio.dart';
import '../dominio/modelo_sucursal.dart';

abstract class RepositorioAdministracion {
  // Dashboard
  Future<ModeloResumenIngresos> obtenerResumenIngresos();

  /// Serie de puntos (fecha, monto) para el gráfico de tendencia del
  /// dashboard. [periodo] es 'semana' | 'mes' | 'anio'.
  Future<List<ModeloPuntoTendencia>> obtenerTendenciaIngresos(String periodo);

  // Sucursales
  Future<List<ModeloSucursal>> obtenerSucursales();
  Future<ModeloSucursal> guardarSucursal(ModeloSucursal sucursal);

  // Servicios
  Future<List<ModeloServicio>> obtenerServicios();
  Future<ModeloServicio> guardarServicio(ModeloServicio servicio);

  // Barberos
  Future<List<ModeloBarbero>> obtenerBarberos();

  // Barberos con columnas acotadas, seguro para pantallas cliente-facing
  // (RPC `obtener_barberos_publicos`, no expone email/telefono).
  Future<List<ModeloBarbero>> obtenerBarberosPublicos({String? sucursalId});
  Future<void> invitarBarbero({
    required String email,
    required String sucursalId,
    required List<String> especialidades,
  });
  Future<void> actualizarEstadoBarbero(String barberoId, bool activo);
  Future<void> guardarNivelBarbero(String barberoId, String? nivel);
  Future<void> guardarSucursalYEspecialidades({
    required String barberoId,
    required String sucursalId,
    required List<String> especialidades,
  });

  // Perfil propio del barbero (foto, descripción, especialidades)
  Future<void> actualizarFotoPerfilPropio(String urlFoto);
  Future<void> actualizarTelefonoPropio(String? telefono);
  Future<void> guardarPerfilBarbero({
    required String? descripcion,
    required List<String> especialidades,
  });

  // Secretarias
  Future<List<ModeloSecretaria>> obtenerSecretarias();
  Future<void> invitarSecretaria({
    required String email,
    required String sucursalId,
  });
  Future<void> revocarSecretaria(String perfilId);

  // Horarios de Barberos
  Future<List<ModeloHorarioBarbero>> obtenerHorariosBarbero(String barberoId);
  Future<List<ModeloHorarioBarbero>> obtenerHorariosBarberoDeBarberos(
    List<String> barberoIds,
  );
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
      final fila = await _cliente
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
  Future<ModeloResumenIngresos> obtenerResumenIngresos() async {
    try {
      final filas = await _cliente.rpc('obtener_resumen_ingresos') as List;
      if (filas.isEmpty) {
        throw const ExcepcionDatosNoEncontrados(
          'No se pudo obtener el resumen de ingresos.',
        );
      }
      return ModeloResumenIngresos.desdeJson(
        filas.first as Map<String, dynamic>,
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloPuntoTendencia>> obtenerTendenciaIngresos(
    String periodo,
  ) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_tendencia_ingresos',
                params: {'p_periodo': periodo},
              )
              as List;
      return filas
          .map(
            (fila) =>
                ModeloPuntoTendencia.desdeJson(fila as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloSucursal>> obtenerSucursales() async {
    try {
      final filas = await _cliente.from('sucursales').select().order('nombre');
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
      if (mapa['id'] == '') {
        mapa.remove('id'); // Dejar que la DB genere el uuid al crear
      }

      final fila = await _cliente
          .from('sucursales')
          .upsert(mapa)
          .select()
          .single();
      return ModeloSucursal.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw ExcepcionDesconocida(e.message.isNotEmpty ? e.message : 'Error al guardar la sucursal.');
    }
  }

  @override
  Future<List<ModeloServicio>> obtenerServicios() async {
    try {
      final filas = await _cliente.from('servicios').select().order('nombre');
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
      if (mapa['id'] == '') {
        mapa.remove('id'); // Dejar que la DB genere el uuid al crear
      }

      final fila = await _cliente
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
  Future<List<ModeloBarbero>> obtenerBarberosPublicos({
    String? sucursalId,
  }) async {
    try {
      final filas =
          await _cliente.rpc(
                'obtener_barberos_publicos',
                params: {'p_sucursal_id': sucursalId},
              )
              as List;
      return filas
          .map((fila) => ModeloBarbero.desdeJson(fila as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
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
  Future<List<ModeloSecretaria>> obtenerSecretarias() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filas = await _cliente
          .from('perfiles')
          .select('id, nombre, email, sucursal_id')
          .eq('barberia_id', barberiaId)
          .eq('rol', 'secretaria')
          .order('nombre');
      return (filas as List)
          .map((f) => ModeloSecretaria.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> invitarSecretaria({
    required String email,
    required String sucursalId,
  }) async {
    try {
      await _cliente.rpc(
        'invitar_secretaria_por_email',
        params: {'email_secretaria': email, 'id_sucursal': sucursalId},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      // El RPC SQL lanza excepciones con raise exception (código P0001)
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<void> revocarSecretaria(String perfilId) async {
    try {
      await _cliente.rpc(
        'revocar_secretaria',
        params: {'p_perfil_id': perfilId},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
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
  Future<void> guardarNivelBarbero(String barberoId, String? nivel) async {
    try {
      await _cliente
          .from('barberos')
          .update({'nivel': nivel})
          .eq('id', barberoId);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarSucursalYEspecialidades({
    required String barberoId,
    required String sucursalId,
    required List<String> especialidades,
  }) async {
    try {
      await _cliente
          .from('barberos')
          .update({'sucursal_id': sucursalId, 'especialidades': especialidades})
          .eq('id', barberoId);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> actualizarFotoPerfilPropio(String urlFoto) async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) {
        throw const ExcepcionPermiso('Sesión no iniciada.');
      }
      await _cliente
          .from('perfiles')
          .update({'url_foto': urlFoto})
          .eq('id', uid);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> actualizarTelefonoPropio(String? telefono) async {
    try {
      final uid = _cliente.auth.currentUser?.id;
      if (uid == null) {
        throw const ExcepcionPermiso('Sesión no iniciada.');
      }
      await _cliente
          .from('perfiles')
          .update({'telefono': telefono})
          .eq('id', uid);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarPerfilBarbero({
    required String? descripcion,
    required List<String> especialidades,
  }) async {
    try {
      await _cliente.rpc(
        'guardar_perfil_barbero',
        params: {
          'p_descripcion': descripcion,
          'p_especialidades': especialidades,
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
  Future<List<ModeloHorarioBarbero>> obtenerHorariosBarberoDeBarberos(
    List<String> barberoIds,
  ) async {
    if (barberoIds.isEmpty) return [];
    try {
      final filas = await _cliente
          .from('horarios_barbero')
          .select()
          .inFilter('barbero_id', barberoIds)
          .order('barbero_id')
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