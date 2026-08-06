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

  Future<String> _obtenerBarberoIdActual() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) {
      throw const ExcepcionPermiso('Sesin no iniciada.');
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
      mapa['barberia_id'] = barberiaId;

      if (mapa['sucursal_id'] == null || (mapa['sucursal_id'] as String).isEmpty) {
        final sucursal = await _cliente
            .from('sucursales')
            .select('id')
            .eq('barberia_id', barberiaId)
            .limit(1)
            .maybeSingle();
        if (sucursal != null) {
          mapa['sucursal_id'] = sucursal['id'];
        }
      }

      if (mapa['id'] == '' || mapa['id'] == null) {
        mapa.remove('id');
      }

      try {
        final fila = await _cliente
            .from('insumos')
            .upsert(mapa)
            .select()
            .single();
        return ModeloInsumo.desdeJson(fila);
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('column') || msg.contains('find')) {
          if (msg.contains('stock_actual')) mapa.remove('stock_actual');
          if (msg.contains('descripcion')) mapa.remove('descripcion');
          if (msg.contains('unidad_medida')) mapa.remove('unidad_medida');
          if (msg.contains('activo')) mapa.remove('activo');

          final fila = await _cliente
              .from('insumos')
              .upsert(mapa)
              .select()
              .single();
          return ModeloInsumo.desdeJson(fila);
        }
        rethrow;
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw ExcepcionDesconocida(e.message.isNotEmpty ? e.message : 'Error al guardar insumo.');
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
      } on PostgrestException catch (_) {
        final barberoId = await _obtenerBarberoIdActual();
        await _cliente.from('reportes_insumo').insert({
          'insumo_id': insumoId,
          'barbero_id': barberoId,
          'tipo': tipo.aTexto(),
          'cantidad': cantidad,
          if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
          if (urlFoto != null && urlFoto.isNotEmpty) 'url_foto': urlFoto,
          'estado': 'pendiente',
        });
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw ExcepcionDesconocida(e.message.isNotEmpty ? e.message : 'Error al reportar insumo.');
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
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }

  @override
  Future<void> revisarReporte({
    required String reporteId,
    required bool aprobar,
  }) async {
    try {
      try {
        await _cliente.rpc(
          'revisar_reporte_insumo',
          params: {'p_reporte_id': reporteId, 'p_aprobar': aprobar},
        );
      } on PostgrestException catch (_) {
        final estadoNuevo = aprobar ? 'aprobado' : 'rechazado';
        await _cliente
            .from('reportes_insumo')
            .update({'estado': estadoNuevo})
            .eq('id', reporteId);
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw ExcepcionPermiso(e.message);
      throw ExcepcionDesconocida(e.message.isNotEmpty ? e.message : 'Error al revisar reporte.');
    }
  }

  @override
  Future<int> contarInsumosBajoMinimo() async {
    try {
      final filas = await _cliente
          .from('insumos')
          .select('id, stock, stock_minimo');
      return (filas as List).where((f) {
        final stock = (f['stock'] as num?)?.toInt() ?? 0;
        final min = (f['stock_minimo'] as num?)?.toInt() ?? 0;
        return stock <= min;
      }).length;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionDesconocida(e.message);
    }
  }
}

final repositorioInventarioProvider = Provider<RepositorioInventario>((ref) {
  return RepositorioInventarioSupabase();
});
