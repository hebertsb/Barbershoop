import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_actividad_usuario.dart';
import '../dominio/modelo_cita_atendida_dia.dart';
import '../dominio/modelo_cita_sin_pago.dart';
import '../dominio/modelo_cliente_nuevo_dia.dart';
import '../dominio/modelo_ingreso_por_metodo.dart';
import '../dominio/modelo_reporte_barbero.dart';
import '../dominio/modelo_reporte_cliente_frecuente.dart';
import '../dominio/modelo_reporte_resumen.dart';
import '../dominio/modelo_reporte_servicio.dart';
import '../dominio/modelo_tasa_ausentismo_barbero.dart';

abstract class RepositorioReportes {
  Future<ModeloReporteResumen> obtenerResumenDetallado({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  Future<List<ModeloReporteServicio>> obtenerReportePorServicio({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  Future<List<ModeloReporteBarbero>> obtenerReportePorBarbero({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  Future<List<ModeloReporteClienteFrecuente>> obtenerReporteClientesFrecuentes({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  /// Citas `completada` de un da especfico (hora local `America/La_Paz`),
  /// para que el dueo revise remotamente qu se atendi ese da.
  Future<List<ModeloCitaAtendidaDia>> obtenerCitasAtendidasDia(DateTime fecha);

  /// Clientes (perfiles `rol = 'cliente'`) registrados en un da especfico
  /// (hora local `America/La_Paz`).
  Future<List<ModeloClienteNuevoDia>> obtenerClientesNuevosDia(DateTime fecha);

  /// Citas `completada` cuyo pago confirmado es menor al `precio_cobrado`
  /// registrado -- seal de plata no reportada o cobrada de menos.
  Future<List<ModeloCitaSinPago>> obtenerCitasSinPagoCompleto({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  /// Ingresos confirmados agrupados por mtodo de pago (efectivo vs
  /// QR/otros mtodos digitales).
  Future<List<ModeloIngresoPorMetodo>> obtenerIngresosPorMetodoPago({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  /// Tasa de ausentismo (canceladas + no_asistio) de cada barbero con al
  /// menos una cita en el rango.
  Future<List<ModeloTasaAusentismoBarbero>> obtenerTasaAusentismoPorBarbero({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  /// Actividad de cada usuario (secretaria/barbero) segn las columnas de
  /// auditora `completado_por`/`cancelado_por` de `citas` (migracin 0050).
  Future<List<ModeloActividadUsuario>> obtenerActividadPorUsuario({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });
}

class RepositorioReportesSupabase implements RepositorioReportes {
  RepositorioReportesSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<ModeloReporteResumen> obtenerResumenDetallado({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_reporte_ingresos_detallado',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      if (res.isEmpty) {
        return const ModeloReporteResumen(
          totalIngresos: 0,
          totalDescuentos: 0,
          citasCompletadas: 0,
          citasCanceladas: 0,
          ticketPromedio: 0,
        );
      }
      return ModeloReporteResumen.desdeJson(res.first as Map<String, dynamic>);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloReporteServicio>> obtenerReportePorServicio({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_reporte_por_servicio',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      return res
          .map(
            (f) => ModeloReporteServicio.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloReporteBarbero>> obtenerReportePorBarbero({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_reporte_por_barbero',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      return res
          .map((f) => ModeloReporteBarbero.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloReporteClienteFrecuente>> obtenerReporteClientesFrecuentes({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_reporte_clientes_frecuentes',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      return res
          .map(
            (f) => ModeloReporteClienteFrecuente.desdeJson(
              f as Map<String, dynamic>,
            ),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  String _formatoFechaRpc(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$anio-$mes-$dia';
  }

  @override
  Future<List<ModeloCitaAtendidaDia>> obtenerCitasAtendidasDia(
    DateTime fecha,
  ) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_citas_atendidas_dia',
                params: {'p_fecha': _formatoFechaRpc(fecha)},
              )
              as List;
      return res
          .map(
            (f) => ModeloCitaAtendidaDia.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloClienteNuevoDia>> obtenerClientesNuevosDia(
    DateTime fecha,
  ) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_clientes_nuevos_dia',
                params: {'p_fecha': _formatoFechaRpc(fecha)},
              )
              as List;
      return res
          .map(
            (f) => ModeloClienteNuevoDia.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloCitaSinPago>> obtenerCitasSinPagoCompleto({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_citas_sin_pago_completo',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      return res
          .map((f) => ModeloCitaSinPago.desdeJson(f as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloIngresoPorMetodo>> obtenerIngresosPorMetodoPago({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_ingresos_por_metodo_pago',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      return res
          .map(
            (f) => ModeloIngresoPorMetodo.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloTasaAusentismoBarbero>> obtenerTasaAusentismoPorBarbero({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      try {
        final res =
            await _cliente.rpc(
                  'obtener_tasa_ausentismo_por_barbero',
                  params: {
                    'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                    'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                  },
                )
                as List;
        return res
            .map(
              (f) => ModeloTasaAusentismoBarbero.desdeJson(
                f as Map<String, dynamic>,
              ),
            )
            .toList();
      } on PostgrestException catch (_) {
        final citas = await _cliente
            .from('citas')
            .select('barbero_id, estado, barberos:barbero_id(perfiles:perfil_id(nombre))')
            .gte('fecha_hora', fechaInicio.toUtc().toIso8601String())
            .lte('fecha_hora', fechaFin.toUtc().toIso8601String());

        final mapaBarberos = <String, Map<String, dynamic>>{};
        for (final c in (citas as List)) {
          final bId = c['barbero_id'] as String?;
          if (bId == null) continue;
          final nombre = c['barberos']?['perfiles']?['nombre'] as String? ?? 'Barbero';
          final est = c['estado'] as String? ?? '';

          if (!mapaBarberos.containsKey(bId)) {
            mapaBarberos[bId] = {
              'barbero_id': bId,
              'nombre_barbero': nombre,
              'total_citas': 0,
              'ausentes': 0,
            };
          }
          mapaBarberos[bId]!['total_citas'] = (mapaBarberos[bId]!['total_citas'] as int) + 1;
          if (est == 'cancelada' || est == 'no_asistio') {
            mapaBarberos[bId]!['ausentes'] = (mapaBarberos[bId]!['ausentes'] as int) + 1;
          }
        }

        return mapaBarberos.values.map((m) {
          final total = m['total_citas'] as int;
          final aus = m['ausentes'] as int;
          final tasa = total > 0 ? (aus / total) * 100 : 0.0;
          return ModeloTasaAusentismoBarbero.desdeJson({
            'barbero_id': m['barbero_id'],
            'nombre_barbero': m['nombre_barbero'],
            'total_citas': total,
            'citas_ausentes': aus,
            'tasa_ausentismo': tasa,
          });
        }).toList();
      }
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }

  @override
  Future<List<ModeloActividadUsuario>> obtenerActividadPorUsuario({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final res =
          await _cliente.rpc(
                'obtener_actividad_por_usuario',
                params: {
                  'p_fecha_inicio': fechaInicio.toUtc().toIso8601String(),
                  'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
                },
              )
              as List;
      return res
          .map(
            (f) => ModeloActividadUsuario.desdeJson(f as Map<String, dynamic>),
          )
          .toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      throw ExcepcionPermiso(e.message);
    }
  }
}

final repositorioReportesProvider = Provider<RepositorioReportes>((ref) {
  return RepositorioReportesSupabase();
});
