import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/enum_tipo_reporte_insumo.dart';
import '../dominio/modelo_insumo.dart';
import '../dominio/modelo_insumo_barbero.dart';
import '../dominio/modelo_reporte_insumo.dart';

abstract class RepositorioInventario {
  Future<List<ModeloInsumo>> obtenerInsumosDeSucursal(String sucursalId);
  Future<ModeloInsumo> guardarInsumo(ModeloInsumo insumo);
  Future<void> eliminarInsumo(String insumoId);

  Future<void> asignarInsumoABarbero({
    required String insumoId,
    required String barberoId,
    required int cantidad,
  });

  Future<List<ModeloInsumoBarbero>> obtenerMisInsumos();

  Future<void> reportarInsumo({
    required String insumoId,
    required TipoReporteInsumo tipo,
    required int cantidad,
    String? descripcion,
    String? urlFoto,
  });

  Future<List<ModeloReporteInsumo>> obtenerBandejaReportes();
  Future<void> revisarReporte({
    required String reporteId,
    required bool aprobar,
  });

  Future<int> contarInsumosBajoMinimo();
}

class RepositorioInventarioSupabase implements RepositorioInventario {
  RepositorioInventarioSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  Future<String> _obtenerBarberiaId() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) {
      throw const ExcepcionPermiso('Sesión no iniciada.');
    }
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
  }

  Future<String> _obtenerBarberoIdActual() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) {
      throw const ExcepcionPermiso('Sesión no iniciada.');
    }
    final fila = await _cliente
        .from('barberos')
        .select('id')
        .eq('perfil_id', uid)
        .maybeSingle();
    final id = fila?['id'] as String?;
    if (id == null) {
      throw const ExcepcionPermiso('No sos un barbero.');
    }
    return id;
  }

  @override
  Future<List<ModeloInsumo>> obtenerInsumosDeSucursal(String sucursalId) async {
    try {
      final filas = await _cliente
          .from('insumos')
          .select()
          .eq('sucursal_id', sucursalId)
          .order('nombre');
      return (filas as List)
          .map((f) => ModeloInsumo.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloInsumo> guardarInsumo(ModeloInsumo insumo) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final mapa = insumo.aJson();
      mapa['barberia_id'] = barberiaId; // Garantizar multi-tenant
      if (mapa['id'] == '') {
        mapa.remove('id'); // Dejar que la DB genere el uuid al crear
      }

      final fila = await _cliente
          .from('insumos')
          .upsert(mapa)
          .select()
          .single();
      return ModeloInsumo.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> eliminarInsumo(String insumoId) async {
    try {
      await _cliente.from('insumos').delete().eq('id', insumoId);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> asignarInsumoABarbero({
    required String insumoId,
    required String barberoId,
    required int cantidad,
  }) async {
    try {
      await _cliente.rpc(
        'asignar_insumo_barbero',
        params: {
          'p_insumo_id': insumoId,
          'p_barbero_id': barberoId,
          'p_cantidad': cantidad,
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
  Future<List<ModeloInsumoBarbero>> obtenerMisInsumos() async {
    try {
      final barberoId = await _obtenerBarberoIdActual();
      final filas = await _cliente
          .from('insumos_barbero')
          .select(
            'barbero_id, insumo_id, cantidad_asignada, insumos:insumo_id(nombre)',
          )
          .eq('barbero_id', barberoId)
          .order('cantidad_asignada', ascending: false);
      return (filas as List)
          .map((f) => ModeloInsumoBarbero.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> reportarInsumo({
    required String insumoId,
    required TipoReporteInsumo tipo,
    required int cantidad,
    String? descripcion,
    String? urlFoto,
  }) async {
    try {
      await _cliente.rpc(
        'reportar_insumo',
        params: {
          'p_insumo_id': insumoId,
          'p_tipo': tipo.aTexto(),
          'p_cantidad': cantidad,
          'p_descripcion': descripcion,
          'p_url_foto': urlFoto,
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
  Future<List<ModeloReporteInsumo>> obtenerBandejaReportes() async {
    try {
      final filas = await _cliente
          .from('reportes_insumo')
          .select(
            'id, barbero_id, insumo_id, tipo, cantidad, descripcion, url_foto, estado, creado_en, '
            'barberos:barbero_id(perfiles:perfil_id(nombre)), insumos:insumo_id(nombre)',
          )
          .eq('estado', 'pendiente')
          .order('creado_en');
      return (filas as List)
          .map((f) => ModeloReporteInsumo.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> revisarReporte({
    required String reporteId,
    required bool aprobar,
  }) async {
    try {
      await _cliente.rpc(
        'revisar_reporte_insumo',
        params: {'p_reporte_id': reporteId, 'p_aprobar': aprobar},
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<int> contarInsumosBajoMinimo() async {
    try {
      final filas = await _cliente
          .from('insumos')
          .select('id, stock, stock_minimo');
      return (filas as List)
          .where((f) => (f['stock'] as int) <= (f['stock_minimo'] as int))
          .length;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }
}

final repositorioInventarioProvider = Provider<RepositorioInventario>((ref) {
  return RepositorioInventarioSupabase();
});
