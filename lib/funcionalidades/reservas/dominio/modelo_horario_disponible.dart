class ModeloHorarioDisponible {
  const ModeloHorarioDisponible({
    required this.barberoId,
    required this.horaInicio,
  });

  final String barberoId;
  final DateTime horaInicio;

  factory ModeloHorarioDisponible.desdeJson(Map<String, dynamic> json) {
    return ModeloHorarioDisponible(
      barberoId: json['barbero_id'] as String,
      horaInicio: DateTime.parse(json['hora_inicio'] as String),
    );
  }
}
