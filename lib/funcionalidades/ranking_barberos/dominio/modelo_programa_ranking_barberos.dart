import 'enum_tipo_premio_ranking.dart';

/// Un programa de ranking de barberos: rango de fechas fijo por sucursal,
/// pesos porcentuales de los 5 factores (deben sumar 100 -- validado acá y
/// en la migración) y el premio del 1er lugar (texto libre + categoría
/// informativa). `nombreGanador` viene de un embed de Supabase, solo
/// presente cuando el repositorio lo pide explícitamente.
class ModeloProgramaRankingBarberos {
  const ModeloProgramaRankingBarberos({
    required this.id,
    required this.barberiaId,
    required this.sucursalId,
    required this.titulo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.pesoCitas,
    required this.pesoIngresos,
    required this.pesoClientes,
    required this.pesoPuntualidad,
    required this.pesoCalificacion,
    required this.tipoPremio,
    required this.descripcionPremio,
    required this.estado,
    required this.premioEntregado,
    this.barberoGanadorId,
    this.nombreGanador,
    this.cerradoEn,
  });

  final String id;
  final String barberiaId;
  final String sucursalId;
  final String titulo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int pesoCitas;
  final int pesoIngresos;
  final int pesoClientes;
  final int pesoPuntualidad;
  final int pesoCalificacion;
  final TipoPremioRanking tipoPremio;
  final String descripcionPremio;

  /// 'activo' | 'cerrado'.
  final String estado;
  final bool premioEntregado;
  final String? barberoGanadorId;
  final String? nombreGanador;
  final DateTime? cerradoEn;

  bool get estaCerrado => estado == 'cerrado';

  /// "Listo para cerrar": sigue activo pero ya pasó su fecha fin.
  bool get listoParaCerrar {
    if (estaCerrado) return false;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return !fechaFin.isAfter(hoySinHora);
  }

  factory ModeloProgramaRankingBarberos.desdeJson(Map<String, dynamic> json) {
    final ganadorJson = json['barbero_ganador'] as Map<String, dynamic>?;
    final perfilGanador = ganadorJson?['perfiles'] as Map<String, dynamic>?;
    return ModeloProgramaRankingBarberos(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      sucursalId: json['sucursal_id'] as String,
      titulo: json['titulo'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      pesoCitas: json['peso_citas'] as int,
      pesoIngresos: json['peso_ingresos'] as int,
      pesoClientes: json['peso_clientes'] as int,
      pesoPuntualidad: json['peso_puntualidad'] as int,
      pesoCalificacion: json['peso_calificacion'] as int,
      tipoPremio: TipoPremioRanking.desdeTexto(json['tipo_premio'] as String),
      descripcionPremio: json['descripcion_premio'] as String,
      estado: json['estado'] as String,
      premioEntregado: json['premio_entregado'] as bool,
      barberoGanadorId: json['barbero_ganador_id'] as String?,
      nombreGanador: perfilGanador?['nombre'] as String?,
      cerradoEn: json['cerrado_en'] != null
          ? DateTime.parse(json['cerrado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'sucursal_id': sucursalId,
      'titulo': titulo,
      'fecha_inicio': fechaInicio.toIso8601String().substring(0, 10),
      'fecha_fin': fechaFin.toIso8601String().substring(0, 10),
      'peso_citas': pesoCitas,
      'peso_ingresos': pesoIngresos,
      'peso_clientes': pesoClientes,
      'peso_puntualidad': pesoPuntualidad,
      'peso_calificacion': pesoCalificacion,
      'tipo_premio': tipoPremio.aTexto(),
      'descripcion_premio': descripcionPremio,
      'estado': estado,
      'premio_entregado': premioEntregado,
    };
  }
}
