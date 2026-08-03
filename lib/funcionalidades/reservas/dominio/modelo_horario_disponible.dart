class ModeloHorarioDisponible {
  const ModeloHorarioDisponible({
    required this.hora,
    required this.disponible,
  });

  final DateTime hora;
  final bool disponible;

  DateTime get horaInicio => hora;

  factory ModeloHorarioDisponible.desdeJson(Map<String, dynamic> json) {
    return ModeloHorarioDisponible(
      hora: DateTime.parse(json['hora'] as String),
      disponible: json['disponible'] as bool? ?? true,
    );
  }
}
