class ModeloProgresoFidelidad {
  const ModeloProgresoFidelidad({
    required this.programaId,
    required this.titulo,
    required this.progresoActual,
    required this.metaCitas,
    required this.puedeReclamar,
  });

  final String programaId;
  final String titulo;
  final int progresoActual;
  final int metaCitas;
  final bool puedeReclamar;

  /// `true` cuando falta 1 sola cita para completar la meta -- usado para
  /// destacar la píldora flotante ("¡ya casi!").
  bool get estaPorCumplirMeta =>
      !puedeReclamar && metaCitas - progresoActual <= 1;

  factory ModeloProgresoFidelidad.desdeJson(Map<String, dynamic> json) {
    return ModeloProgresoFidelidad(
      programaId: json['programa_id'] as String,
      titulo: json['titulo'] as String,
      progresoActual: json['progreso_actual'] as int,
      metaCitas: json['meta_citas'] as int,
      puedeReclamar: json['puede_reclamar'] as bool,
    );
  }
}
