class ModeloHorarioBarbero {
  ModeloHorarioBarbero({
    required this.id,
    required this.barberoId,
    required this.diaSemana,
    String? horaApertura,
    String? horaCierre,
    String? horaInicio,
    String? horaFin,
    this.barberiaId,
  })  : horaApertura = horaApertura ?? horaInicio ?? '09:00',
        horaCierre = horaCierre ?? horaFin ?? '18:00';

  final String id;
  final String barberoId;
  final int diaSemana;
  final String horaApertura;
  final String horaCierre;

  /// ID de la barbería — puede ser null si el horario se cargó sin join.
  final String? barberiaId;

  String get horaInicio => horaApertura;
  String get horaFin => horaCierre;

  factory ModeloHorarioBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloHorarioBarbero(
      id: json['id'] as String,
      barberoId: json['barbero_id'] as String,
      diaSemana: json['dia_semana'] as int,
      horaApertura:
          (json['hora_apertura'] ?? json['hora_inicio']) as String,
      horaCierre: (json['hora_cierre'] ?? json['hora_fin']) as String,
      barberiaId: json['barberia_id'] as String?,
    );
  }
}
