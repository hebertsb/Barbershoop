/// Tasa de ausentismo de un barbero: porcentaje de citas que fueron
/// canceladas o no atendidas (no-show) dentro del período analizado.
class ModeloTasaAusentismoBarbero {
  const ModeloTasaAusentismoBarbero({
    required this.barberoId,
    required this.nombre,
    required this.citasCanceladas,
    required this.tasaPorcentaje,
    this.totalCitasValue = 0,
    this.canceladasValue = 0,
    this.noAsistioValue = 0,
  });

  final String barberoId;
  final String nombre;
  final int citasCanceladas;

  /// Porcentaje de ausentismo ya calculado, ej: 12.5 = 12.5%.
  final double tasaPorcentaje;

  // Desglose detallado para la UI
  final int totalCitasValue;
  final int canceladasValue;
  final int noAsistioValue;

  // ── Getters alias para compatibilidad con widgets ──────────────────────

  /// Nombre del barbero (alias de [nombre]).
  String get barberoNombre => nombre;

  /// Tasa de ausentismo en porcentaje (alias de [tasaPorcentaje]).
  double get tasaAusentismo => tasaPorcentaje;

  /// Total de citas en el período.
  int get totalCitas => totalCitasValue;

  /// Citas canceladas.
  int get canceladas => canceladasValue;

  /// Citas donde el cliente no se presentó.
  int get noAsistio => noAsistioValue;

  factory ModeloTasaAusentismoBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloTasaAusentismoBarbero(
      barberoId: json['barbero_id'] as String,
      nombre: json['nombre'] as String? ?? 'Barbero',
      citasCanceladas: json['citas_canceladas'] as int? ?? 0,
      tasaPorcentaje:
          (json['tasa_porcentaje'] as num? ?? 0).toDouble(),
      totalCitasValue: json['total_citas'] as int? ?? 0,
      canceladasValue: json['canceladas'] as int? ?? 0,
      noAsistioValue: json['no_asistio'] as int? ?? 0,
    );
  }
}
