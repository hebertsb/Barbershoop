import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_configuracion_pagos.dart';
import '../dominio/modelo_marca_barberia.dart';

abstract class RepositorioAjustes {
  Future<ModeloConfiguracionPagos> obtenerConfiguracionPagos();

  Future<void> guardarConfiguracionPagos(ModeloConfiguracionPagos config);

  Future<int> obtenerMinutosToleranciaNoAsistio();

  Future<void> guardarMinutosToleranciaNoAsistio(int minutos);

  Future<String> obtenerInstruccionesCita();

  Future<void> guardarInstruccionesCita(String texto);

  /// Solo lectura: el valor real lo define/usa `cancelar_cita_cliente`
  /// (0031) del lado servidor; acá se lee para ocultar "Reprogramar" en el
  /// cliente con el mismo umbral, sin admin UI nueva para editarlo.
  Future<int> obtenerMinutosMinimosCancelacion();

  // Marca (nombre, slogan, logo, color de acento)
  Future<ModeloMarcaBarberia> obtenerMarcaBarberia();
  Future<void> guardarMarcaBarberia(ModeloMarcaBarberia marca);
}

class RepositorioAjustesSupabase implements RepositorioAjustes {
  RepositorioAjustesSupabase({SupabaseClient? cliente})
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

  @override
  Future<ModeloConfiguracionPagos> obtenerConfiguracionPagos() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filas = await _cliente
          .from('configuraciones_barberia')
          .select('clave, valor')
          .eq('barberia_id', barberiaId)
          .inFilter('clave', ModeloConfiguracionPagos.claves);

      final json = <String, dynamic>{
        for (final fila in filas) fila['clave'] as String: fila['valor'],
      };

      return ModeloConfiguracionPagos.desdeJson(json);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarConfiguracionPagos(
    ModeloConfiguracionPagos config,
  ) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final valores = config.aJson();
      final filas = [
        for (final entrada in valores.entries)
          {
            'barberia_id': barberiaId,
            'clave': entrada.key,
            'valor': entrada.value,
          },
      ];
      await _cliente
          .from('configuraciones_barberia')
          .upsert(filas, onConflict: 'barberia_id,clave');
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  static const _claveMinutosToleranciaNoAsistio =
      'minutos_tolerancia_no_asistio';

  @override
  Future<int> obtenerMinutosToleranciaNoAsistio() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final fila = await _cliente
          .from('configuraciones_barberia')
          .select('valor')
          .eq('barberia_id', barberiaId)
          .eq('clave', _claveMinutosToleranciaNoAsistio)
          .maybeSingle();

      final valor = fila?['valor'];
      if (valor is Map<String, dynamic>) {
        final minutos = valor['minutos'];
        if (minutos is num) return minutos.toInt();
      }
      return 15;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarMinutosToleranciaNoAsistio(int minutos) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      await _cliente.from('configuraciones_barberia').upsert({
        'barberia_id': barberiaId,
        'clave': _claveMinutosToleranciaNoAsistio,
        'valor': {'minutos': minutos},
      }, onConflict: 'barberia_id,clave');
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  static const _claveInstruccionesCita = 'instrucciones_cita';
  static const _instruccionesCitaDefault =
      'Preséntate 10 minutos antes de tu cita. Si necesitás cancelar o '
      'reprogramar, hacelo con anticipación desde la app.';

  @override
  Future<String> obtenerInstruccionesCita() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final fila = await _cliente
          .from('configuraciones_barberia')
          .select('valor')
          .eq('barberia_id', barberiaId)
          .eq('clave', _claveInstruccionesCita)
          .maybeSingle();

      final valor = fila?['valor'];
      if (valor is Map<String, dynamic>) {
        final texto = valor['texto'];
        if (texto is String && texto.trim().isNotEmpty) return texto;
      }
      return _instruccionesCitaDefault;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarInstruccionesCita(String texto) async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      await _cliente.from('configuraciones_barberia').upsert({
        'barberia_id': barberiaId,
        'clave': _claveInstruccionesCita,
        'valor': {'texto': texto},
      }, onConflict: 'barberia_id,clave');
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  static const _claveMinutosMinimosCancelacion =
      'minutos_minimos_cancelacion_cliente';

  @override
  Future<int> obtenerMinutosMinimosCancelacion() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final fila = await _cliente
          .from('configuraciones_barberia')
          .select('valor')
          .eq('barberia_id', barberiaId)
          .eq('clave', _claveMinutosMinimosCancelacion)
          .maybeSingle();

      final valor = fila?['valor'];
      if (valor is Map<String, dynamic>) {
        final minutos = valor['minutos'];
        if (minutos is num) return minutos.toInt();
      }
      return 120;
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  static const _claveColorAcento = 'color_acento';

  @override
  Future<ModeloMarcaBarberia> obtenerMarcaBarberia() async {
    try {
      final barberiaId = await _obtenerBarberiaId();
      final filaBarberia = await _cliente
          .from('barberias')
          .select('nombre, slogan, url_logo')
          .eq('id', barberiaId)
          .single();
      final filaColor = await _cliente
          .from('configuraciones_barberia')
          .select('valor')
          .eq('barberia_id', barberiaId)
          .eq('clave', _claveColorAcento)
          .maybeSingle();

      String? colorAcentoHex;
      final valorColor = filaColor?['valor'];
      if (valorColor is Map<String, dynamic>) {
        final hex = valorColor['hex'];
        if (hex is String) colorAcentoHex = hex;
      }

      return ModeloMarcaBarberia.desdeJson({
        'nombre': filaBarberia['nombre'],
        'slogan': filaBarberia['slogan'],
        'url_logo': filaBarberia['url_logo'],
        'color_acento_hex': colorAcentoHex,
      });
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> guardarMarcaBarberia(ModeloMarcaBarberia marca) async {
    try {
      final json = marca.aJson();
      // guardar_marca_barberia hace el update de `barberias` y el upsert de
      // `configuraciones_barberia` dentro de una sola función SQL: si el
      // segundo paso falla, Postgres revierte también el primero (mismo
      // motivo que reemplazar_horarios_barbero, 0006) -- dos llamadas
      // .update()/.upsert() sueltas desde el cliente podían dejar el nombre
      // guardado pero el color de acento sin actualizar (o viceversa).
      await _cliente.rpc(
        'guardar_marca_barberia',
        params: {
          'p_nombre': json['nombre'],
          'p_slogan': json['slogan'],
          'p_url_logo': json['url_logo'],
          'p_color_acento_hex': json['color_acento_hex'],
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

final repositorioAjustesProvider = Provider<RepositorioAjustes>((ref) {
  return RepositorioAjustesSupabase();
});