class ModeloInsumoBarbero {
  const ModeloInsumoBarbero({
    required this.id,
    required this.barberoId,
    required this.insumoId,
    required this.cantidadAsignada,
    this.nombreInsumoCache,
    this.unidadMedidaCache,
  });

  final String id;
  final String barberoId;
  final String insumoId;
  final double cantidadAsignada;
  final String? nombreInsumoCache;
  final String? unidadMedidaCache;

  /// Nombre del insumo asignado.
  String get nombreInsumo => nombreInsumoCache ?? 'Insumo';

  /// Unidad de medida.
  String get unidadMedida => unidadMedidaCache ?? 'unidad';

  /// Cantidad formateada con su unidad.
  String get cantidadFormateada {
    final cantStr = cantidadAsignada % 1 == 0
        ? cantidadAsignada.toInt().toString()
        : cantidadAsignada.toStringAsFixed(1);
    return '$cantStr $unidadMedida';
  }

  factory ModeloInsumoBarbero.desdeJson(Map<String, dynamic> json) {
    String? nombre;
    String? unidad;
    if (json['insumos'] is Map) {
      final insumoMap = json['insumos'] as Map<String, dynamic>;
      nombre = insumoMap['nombre'] as String?;
      unidad = insumoMap['unidad_medida'] as String?;
    }

    return ModeloInsumoBarbero(
      id: json['id'] as String? ?? '',
      barberoId: json['barbero_id'] as String? ?? '',
      insumoId: json['insumo_id'] as String? ?? '',
      cantidadAsignada: (json['cantidad_asignada'] as num? ?? 0).toDouble(),
      nombreInsumoCache: nombre ?? (json['nombre_insumo'] ?? json['insumo_nombre']) as String?,
      unidadMedidaCache: unidad ?? json['unidad_medida'] as String?,
    );
  }
}
