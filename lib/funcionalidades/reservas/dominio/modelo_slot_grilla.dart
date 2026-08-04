import '../../../../nucleo/utilidades/parsear_fecha_utc.dart';

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
      horaInicio: parsearFechaUtc(json['hora_inicio'] as String?),
      disponible: json['disponible'] as bool? ?? true,
    );
  }
}
