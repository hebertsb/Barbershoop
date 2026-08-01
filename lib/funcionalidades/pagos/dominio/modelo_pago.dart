import 'enum_estado_pago.dart';
import 'enum_metodo_pago.dart';

class ModeloPago {
  const ModeloPago({
    required this.id,
    required this.barberiaId,
    required this.citaId,
    required this.monto,
    required this.metodo,
    required this.estado,
    this.urlComprobante,
    this.verificadoPor,
    required this.fecha,
    this.nombreCliente,
    this.fechaHoraCita,
  });

  final String id;
  final String barberiaId;
  final String citaId;
  final double monto;
  final MetodoPago metodo;
  final EstadoPago estado;
  final String? urlComprobante;
  final String? verificadoPor;
  final DateTime fecha;

  // Campos informativos obtenidos via embed a citas/perfiles, solo presentes
  // cuando la consulta los pide explícitamente (ej. la bandeja de verificación).
  final String? nombreCliente;
  final DateTime? fechaHoraCita;

  factory ModeloPago.desdeJson(Map<String, dynamic> json) {
    final citaJson = json['citas'] as Map<String, dynamic>?;
    final perfilJson = citaJson?['perfiles'] as Map<String, dynamic>?;
    return ModeloPago(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      citaId: json['cita_id'] as String,
      monto: (json['monto'] as num).toDouble(),
      metodo: MetodoPago.desdeTexto(json['metodo'] as String),
      estado: EstadoPago.desdeTexto(json['estado'] as String),
      urlComprobante: json['url_comprobante'] as String?,
      verificadoPor: json['verificado_por'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      nombreCliente: perfilJson?['nombre'] as String?,
      fechaHoraCita: citaJson?['fecha_hora'] != null
          ? DateTime.parse(citaJson!['fecha_hora'] as String)
          : null,
    );
  }
}
