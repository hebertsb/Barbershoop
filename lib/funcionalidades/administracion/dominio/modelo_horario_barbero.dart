class ModeloHorarioBarbero {
  const ModeloHorarioBarbero({
    required this.id,
    required this.barberoId,
    required this.barberiaId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  final String id;
  final String barberoId;
  final String barberiaId;
  final int diaSemana; // 0: Domingo, 1: Lunes, ..., 6: Sábado
  final String horaInicio; // "HH:MM:SS" o "HH:MM"
  final String horaFin; // "HH:MM:SS" o "HH:MM"

  factory ModeloHorarioBarbero.desdeJson(Map<String, dynamic> json) {
    // Normalizar formato de hora para quitar segundos si vienen de la DB
    String normalizarHora(String hora) {
      final partes = hora.split(':');
      if (partes.length >= 2) {
        return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';
      }
      return hora;
    }

    return ModeloHorarioBarbero(
      id: json['id'] as String,
      barberoId: json['barbero_id'] as String,
      barberiaId: json['barberia_id'] as String,
      diaSemana: json['dia_semana'] as int,
      horaInicio: normalizarHora(json['hora_inicio'] as String),
      horaFin: normalizarHora(json['hora_fin'] as String),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barbero_id': barberoId,
      'barberia_id': barberiaId,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    };
  }

  ModeloHorarioBarbero copyWith({
    int? diaSemana,
    String? horaInicio,
    String? horaFin,
  }) {
    return ModeloHorarioBarbero(
      id: id,
      barberoId: barberoId,
      barberiaId: barberiaId,
      diaSemana: diaSemana ?? this.diaSemana,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
    );
  }
}
