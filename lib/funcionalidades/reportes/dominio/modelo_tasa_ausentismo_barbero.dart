class ModeloTasaAusentismoBarbero {
  const ModeloTasaAusentismoBarbero({
    required this.barberoId,
    required this.barberoNombre,
    required this.totalCitas,
    required this.noAsistio,
  });

  final String barberoId;
  final String barberoNombre;
  final int totalCitas;
  final int noAsistio;

  double get tasaAusentismo => totalCitas == 0 ? 0 : noAsistio / totalCitas;

  factory ModeloTasaAusentismoBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloTasaAusentismoBarbero(
      barberoId: json['barbero_id'] as String,
      barberoNombre: json['barbero_nombre'] as String,
      totalCitas: json['total_citas'] as int,
      noAsistio: json['no_asistio'] as int,
    );
  }
}
