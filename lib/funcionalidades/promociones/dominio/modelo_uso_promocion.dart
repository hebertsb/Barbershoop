/// Registro de uso de una promoción por parte de un cliente.
/// [vecesUsada] indica cuántas veces el cliente ha usado esta promoción.
class ModeloUsoPromocion {
  const ModeloUsoPromocion({
    required this.id,
    required this.promocionId,
    required this.clienteId,
    required this.fecha,
    this.clienteNombreVal,
    this.vecesUsadaVal = 1,
  });

  final String id;
  final String promocionId;
  final String clienteId;
  final DateTime fecha;
  final String? clienteNombreVal;
  final int vecesUsadaVal;

  // ── Getters alias ──────────────────────────────────────────────────────

  /// Nombre del cliente que usó la promoción.
  String get clienteNombre => clienteNombreVal ?? 'Cliente';

  /// Cantidad de veces que el cliente ha usado esta promoción.
  int get vecesUsada => vecesUsadaVal;

  factory ModeloUsoPromocion.desdeJson(Map<String, dynamic> json) {
    return ModeloUsoPromocion(
      id: json['id'] as String,
      promocionId: json['promocion_id'] as String,
      clienteId: json['cliente_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      clienteNombreVal: json['cliente_nombre'] as String?,
      vecesUsadaVal: json['veces_usada'] as int? ?? 1,
    );
  }
}
