class ModeloUsoPromocion {
  const ModeloUsoPromocion({
    required this.clienteId,
    required this.clienteNombre,
    required this.vecesUsada,
  });

  final String clienteId;
  final String clienteNombre;
  final int vecesUsada;

  factory ModeloUsoPromocion.desdeJson(Map<String, dynamic> json) {
    return ModeloUsoPromocion(
      clienteId: json['cliente_id'] as String,
      clienteNombre: json['cliente_nombre'] as String,
      vecesUsada: json['veces_usada'] as int,
    );
  }
}
