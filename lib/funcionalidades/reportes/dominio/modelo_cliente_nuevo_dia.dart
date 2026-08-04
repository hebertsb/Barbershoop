import '../../../../nucleo/utilidades/parsear_fecha_utc.dart';

class ModeloClienteNuevoDia {
  const ModeloClienteNuevoDia({
    required this.clienteId,
    required this.nombre,
    this.telefono,
    required this.horaRegistro,
  });

  final String clienteId;
  final String nombre;
  final String? telefono;
  final DateTime horaRegistro;

  factory ModeloClienteNuevoDia.desdeJson(Map<String, dynamic> json) {
    return ModeloClienteNuevoDia(
      clienteId: json['cliente_id'] as String,
      nombre: json['nombre'] as String? ?? 'Cliente',
      telefono: json['telefono'] as String?,
      horaRegistro: parsearFechaUtc(json['hora_registro'] as String?),
    );
  }
}