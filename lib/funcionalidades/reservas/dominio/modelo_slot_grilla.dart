class ModeloSlotGrilla {
  const ModeloSlotGrilla({
    required this.horaInicio,
    required this.disponible,
  });

  final DateTime horaInicio;
  final bool disponible;

  bool get libre => disponible;

  factory ModeloSlotGrilla.desdeJson(Map<String, dynamic> json) {
    return ModeloSlotGrilla(
      horaInicio: DateTime.parse(json['hora_inicio'] as String),
      disponible: json['disponible'] as bool? ?? true,
    );
  }
}
