class ModeloProgramaFidelidad {
  const ModeloProgramaFidelidad({
    required this.id,
    required this.barberiaId,
    required this.titulo,
    required this.metaCitas,
    required this.activo,
    this.serviciosIds = const [],
    this.fechaInicio,
    this.fechaFin,
  });

  final String id;
  final String barberiaId;
  final String titulo;
  final int metaCitas;
  final bool activo;

  /// Servicios que cuentan para el progreso -- vacío = cuentan todos.
  final List<String> serviciosIds;

  /// Rango fijo de vigencia del programa (mismo criterio que
  /// `promociones.fecha_inicio`/`fecha_fin`) -- `null` = sin límite en ese
  /// extremo.
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  factory ModeloProgramaFidelidad.desdeJson(Map<String, dynamic> json) {
    return ModeloProgramaFidelidad(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      titulo: json['titulo'] as String,
      metaCitas: json['meta_citas'] as int,
      activo: json['activo'] as bool,
      serviciosIds:
          (json['servicios_ids'] as List?)?.cast<String>() ?? const [],
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'titulo': titulo,
      'meta_citas': metaCitas,
      'activo': activo,
      'servicios_ids': serviciosIds,
      'fecha_inicio': fechaInicio?.toIso8601String().split('T').first,
      'fecha_fin': fechaFin?.toIso8601String().split('T').first,
    };
  }
}
