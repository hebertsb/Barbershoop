class ModeloInsumoBarbero {
  const ModeloInsumoBarbero({
    required this.id,
    required this.barberoId,
    required this.insumoId,
    required this.cantidadAsignada,
    this.nombreInsumoCache,
  });

  final String id;
  final String barberoId;
  final String insumoId;
  final double cantidadAsignada;
  final String? nombreInsumoCache;

  /// Nombre del insumo asignado.
  String get nombreInsumo => nombreInsumoCache ?? 'Insumo';

  factory ModeloInsumoBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloInsumoBarbero(
      id: json['id'] as String,
      barberoId: json['barbero_id'] as String,
      insumoId: json['insumo_id'] as String,
      cantidadAsignada: (json['cantidad_asignada'] as num? ?? 0).toDouble(),
      nombreInsumoCache: (json['nombre_insumo'] ?? json['insumo_nombre']) as String?,
    );
  }
}
