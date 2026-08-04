import 'enum_estado_pago.dart';
import 'enum_metodo_pago.dart';

class ModeloPago {
  const ModeloPago({
    required this.id,
    required this.citaId,
    required this.monto,
    required this.metodo,
    required this.estado,
    this.comprobanteUrl,
    this.creadoEn,
    this.clienteNombreCache,
    this.fechaHoraCitaCache,
  });

  final String id;
  final String citaId;
  final double monto;
  final MetodoPago metodo;
  final EstadoPago estado;
  final String? comprobanteUrl;
  final DateTime? creadoEn;
  final String? clienteNombreCache;
  final DateTime? fechaHoraCitaCache;

  /// Alias de [comprobanteUrl].
  String? get urlComprobante => comprobanteUrl;

  /// Nombre del cliente pagador.
  String? get nombreCliente => clienteNombreCache;

  /// Fecha y hora de la cita asociada.
  DateTime? get fechaHoraCita => fechaHoraCitaCache ?? creadoEn;

  factory ModeloPago.desdeJson(Map<String, dynamic> json) {
    String? cNombre;
    DateTime? fCita;
    final citaMap = json['citas'];
    if (citaMap is Map<String, dynamic>) {
      final perfilesMap = citaMap['perfiles'];
      if (perfilesMap is Map<String, dynamic>) {
        cNombre = perfilesMap['nombre'] as String?;
      }
      cNombre ??= (citaMap['cliente_nombre'] ?? citaMap['nombre_cliente']) as String?;
      if (citaMap['fecha_hora'] != null) {
        fCita = DateTime.tryParse(citaMap['fecha_hora'] as String);
      } else if (citaMap['fecha'] != null) {
        fCita = DateTime.tryParse(citaMap['fecha'] as String);
      }
    }

    return ModeloPago(
      id: json['id'] as String? ?? '',
      citaId: json['cita_id'] as String? ?? '',
      monto: (json['monto'] as num? ?? 0).toDouble(),
      metodo: MetodoPago.desdeTexto(json['metodo'] as String? ?? ''),
      estado: EstadoPago.desdeTexto(json['estado'] as String? ?? ''),
      comprobanteUrl: (json['comprobante_url'] ?? json['url_comprobante']) as String?,
      creadoEn: json['creado_en'] == null ? null : DateTime.tryParse(json['creado_en'] as String),
      clienteNombreCache: cNombre ?? json['cliente_nombre'] as String?,
      fechaHoraCitaCache: fCita ?? (json['fecha_cita'] == null ? null : DateTime.tryParse(json['fecha_cita'] as String)),
    );
  }
}
