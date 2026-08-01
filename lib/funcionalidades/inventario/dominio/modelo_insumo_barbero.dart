class ModeloInsumoBarbero {
  const ModeloInsumoBarbero({
    required this.insumoId,
    required this.nombreInsumo,
    required this.cantidadAsignada,
  });

  final String insumoId;
  final String nombreInsumo;
  final int cantidadAsignada;

  factory ModeloInsumoBarbero.desdeJson(Map<String, dynamic> json) {
    final insumoMap = json['insumos'] as Map<String, dynamic>?;
    return ModeloInsumoBarbero(
      insumoId: json['insumo_id'] as String,
      nombreInsumo:
          (insumoMap?['nombre'] ?? json['nombre_insumo'] ?? 'Insumo')
              as String,
      cantidadAsignada: json['cantidad_asignada'] as int,
    );
  }
}
