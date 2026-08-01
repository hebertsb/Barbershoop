/// Un slot fijo de la grilla de horarios de un barbero para un día: libre
/// (reservable) o bloqueado (ya ocupado / fuera de su horario de trabajo).
class ModeloSlotGrilla {
  const ModeloSlotGrilla({required this.horaInicio, required this.libre});

  final DateTime horaInicio;
  final bool libre;

  factory ModeloSlotGrilla.desdeJson(Map<String, dynamic> json) {
    return ModeloSlotGrilla(
      horaInicio: DateTime.parse(json['hora_inicio'] as String),
      libre: json['libre'] as bool,
    );
  }
}
