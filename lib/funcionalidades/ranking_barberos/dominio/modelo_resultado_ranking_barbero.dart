import 'modelo_insignia_ranking_barbero.dart';

/// Resultado completo de un barbero dentro de un programa de ranking.
/// Incluye métricas individuales y su posición en cada dimensión para
/// mostrar el podio y el desglose en el detalle del ranking.
class ModeloResultadoRankingBarbero {
  const ModeloResultadoRankingBarbero({
    required this.barberoId,
    required this.nombre,
    required this.posicion,
    required this.puntuacionTotal,
    required this.totalIngresos,
    required this.totalCitas,
    required this.promedioCalificacion,
    required this.insignias,
    this.citasCompletadas = 0,
    this.ingresosGenerados = 0,
    this.clientesDistintos = 0,
    this.tasaNoShow = 0,
    this.calificacionPromedio = 0,
    this.puestoCitas = 0,
    this.puestoIngresos = 0,
    this.puestoClientes = 0,
    this.puestoPuntualidad = 0,
    this.puestoCalificacion = 0,
  });

  final String barberoId;
  final String nombre;
  final int posicion;
  final double puntuacionTotal;
  final double totalIngresos;
  final int totalCitas;
  final double promedioCalificacion;
  final List<ModeloInsigniaRankingBarbero> insignias;

  // Métricas detalladas para el podio y desglose
  final int citasCompletadas;
  final double ingresosGenerados;
  final int clientesDistintos;

  /// Tasa de no-asistencia en rango [0, 1]. Ej: 0.15 = 15% de no-shows.
  final double tasaNoShow;

  /// Calificación promedio de reseñas de clientes (0–5).
  final double calificacionPromedio;

  // Posiciones en cada dimensión del ranking
  final int puestoCitas;
  final int puestoIngresos;
  final int puestoClientes;
  final int puestoPuntualidad;
  final int puestoCalificacion;

  // ── Getters alias ────────────────────────────────────────────────────

  /// Alias de [posicion]: lugar en el ranking general.
  int get puesto => posicion;

  /// Alias de [puntuacionTotal]: puntaje acumulado del barbero.
  double get puntaje => puntuacionTotal;

  factory ModeloResultadoRankingBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloResultadoRankingBarbero(
      barberoId: json['barbero_id'] as String,
      nombre: json['nombre'] as String? ?? 'Barbero',
      posicion: json['posicion'] as int? ?? 1,
      puntuacionTotal: (json['puntuacion_total'] as num? ?? 0).toDouble(),
      totalIngresos: (json['total_ingresos'] as num? ?? 0).toDouble(),
      totalCitas: json['total_citas'] as int? ?? 0,
      promedioCalificacion:
          (json['promedio_calificacion'] as num? ?? 0).toDouble(),
      insignias: (json['insignias'] as List<dynamic>?)
              ?.map((e) => ModeloInsigniaRankingBarbero.desdeJson(
                    e as Map<String, dynamic>,
                  ))
              .toList() ??
          const [],
      citasCompletadas: json['citas_completadas'] as int? ?? 0,
      ingresosGenerados:
          (json['ingresos_generados'] as num? ?? 0).toDouble(),
      clientesDistintos: json['clientes_distintos'] as int? ?? 0,
      tasaNoShow: (json['tasa_no_show'] as num? ?? 0).toDouble(),
      calificacionPromedio:
          (json['calificacion_promedio'] as num? ?? 0).toDouble(),
      puestoCitas: json['puesto_citas'] as int? ?? 0,
      puestoIngresos: json['puesto_ingresos'] as int? ?? 0,
      puestoClientes: json['puesto_clientes'] as int? ?? 0,
      puestoPuntualidad: json['puesto_puntualidad'] as int? ?? 0,
      puestoCalificacion: json['puesto_calificacion'] as int? ?? 0,
    );
  }
}
