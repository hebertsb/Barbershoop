class ModeloProgresoFidelidad {
  const ModeloProgresoFidelidad({
    required this.id,
    required this.programaId,
    required this.clienteId,
    required this.sellosActuales,
    required this.completado,
    this.metaCitasCache,
    this.tituloCache,
  });

  final String id;
  final String programaId;
  final String clienteId;
  final int sellosActuales;
  final bool completado;
  final int? metaCitasCache;
  final String? tituloCache;

  /// Alias de [sellosActuales].
  int get progresoActual => sellosActuales;

  /// Cantidad de citas requeridas (meta) para el programa.
  int get metaCitas => metaCitasCache ?? 5;

  /// Título o nombre del programa de fidelidad.
  String get titulo => tituloCache ?? 'Programa de Fidelidad (5 Cortes)';

  /// Indica si el cliente acumuló suficientes sellos para reclamar la recompensa.
  bool get puedeReclamar => sellosActuales >= metaCitas;

  /// Indica si le faltan 2 o menos citas para completar la meta.
  bool get estaPorCumplirMeta => sellosActuales >= (metaCitas - 2) && !puedeReclamar;

  factory ModeloProgresoFidelidad.desdeJson(Map<String, dynamic> json) {
    return ModeloProgresoFidelidad(
      id: json['id'] as String? ?? '',
      programaId: json['programa_id'] as String? ?? '',
      clienteId: json['cliente_id'] as String? ?? '',
      sellosActuales: json['sellos_actuales'] as int? ?? json['sellos'] as int? ?? 0,
      completado: json['completado'] as bool? ?? false,
      metaCitasCache: (json['meta_citas'] ?? json['sellos_requeridos'] ?? json['meta']) as int?,
      tituloCache: (json['titulo'] ?? json['nombre_programa'] ?? json['nombre']) as String?,
    );
  }
}
