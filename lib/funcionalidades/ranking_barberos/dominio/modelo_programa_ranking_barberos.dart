import 'enum_tipo_premio_ranking.dart';

/// Programa de ranking de barberos: define los pesos de cada métrica
/// (citas, ingresos, clientes, puntualidad, calificación) y el premio.
/// Los pesos son enteros (0–100) que deben sumar 100.
class ModeloProgramaRankingBarberos {
  ModeloProgramaRankingBarberos({
    required this.id,
    required this.barberiaId,
    String? nombre,
    String? titulo,
    required this.pesoIngresos,
    required this.pesoCitas,
    required this.pesoCalificacion,
    required this.pesoPuntualidad,
    this.pesoClientes = 0,
    this.estado = 'activo',
    DateTime? fechaInicio,
    DateTime? fechaFin,
    this.activo = true,
    this.sucursalId,
    this.tipoPremio = TipoPremioRanking.dinero,
    this.descripcionPremio = '',
    this.premioEntregado = false,
    this.nombreGanador,
  })  : nombre = nombre ?? titulo ?? 'Programa Ranking',
        fechaInicio = fechaInicio ?? DateTime.now(),
        fechaFin =
            fechaFin ?? DateTime.now().add(const Duration(days: 30));

  final String id;
  final String barberiaId;
  final String nombre;
  final int pesoIngresos;
  final int pesoCitas;
  final int pesoCalificacion;
  final int pesoPuntualidad;
  final int pesoClientes;
  final String estado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;
  final String? sucursalId;
  final TipoPremioRanking tipoPremio;
  final String descripcionPremio;
  final bool premioEntregado;
  final String? nombreGanador;

  // ── Getters alias ──────────────────────────────────────────────────────

  /// Alias de [nombre].
  String get titulo => nombre;

  /// El programa está cerrado cuando su estado es 'cerrado'.
  bool get estaCerrado => estado == 'cerrado';

  /// El programa está listo para cerrar cuando su fecha fin ya pasó pero
  /// aún no fue cerrado formalmente.
  bool get listoParaCerrar =>
      !estaCerrado && fechaFin.isBefore(DateTime.now());

  factory ModeloProgramaRankingBarberos.desdeJson(Map<String, dynamic> json) {
    return ModeloProgramaRankingBarberos(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String? ?? 'Programa Ranking',
      pesoIngresos:
          ((json['peso_ingresos'] as num?)?.toInt()) ?? 20,
      pesoCitas: ((json['peso_citas'] as num?)?.toInt()) ?? 20,
      pesoCalificacion:
          ((json['peso_calificacion'] as num?)?.toInt()) ?? 20,
      pesoPuntualidad:
          ((json['peso_puntualidad'] as num?)?.toInt()) ?? 20,
      pesoClientes:
          ((json['peso_clientes'] as num?)?.toInt()) ?? 0,
      estado: json['estado'] as String? ?? 'activo',
      fechaInicio: json['fecha_inicio'] == null
          ? null
          : DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] == null
          ? null
          : DateTime.parse(json['fecha_fin'] as String),
      activo: json['activo'] as bool? ?? true,
      sucursalId: json['sucursal_id'] as String?,
      tipoPremio: json['tipo_premio'] == null
          ? TipoPremioRanking.dinero
          : TipoPremioRanking.desdeTexto(json['tipo_premio'] as String),
      descripcionPremio: json['descripcion_premio'] as String? ?? '',
      premioEntregado: json['premio_entregado'] as bool? ?? false,
      nombreGanador: json['nombre_ganador'] as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'nombre': nombre,
      'peso_ingresos': pesoIngresos,
      'peso_citas': pesoCitas,
      'peso_calificacion': pesoCalificacion,
      'peso_puntualidad': pesoPuntualidad,
      'peso_clientes': pesoClientes,
      'estado': estado,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'activo': activo,
      if (sucursalId != null) 'sucursal_id': sucursalId,
      'tipo_premio': tipoPremio.aTexto,
      'descripcion_premio': descripcionPremio,
      'premio_entregado': premioEntregado,
      if (nombreGanador != null) 'nombre_ganador': nombreGanador,
    };
  }
}
