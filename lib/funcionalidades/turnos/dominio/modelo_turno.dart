import 'enum_estado_turno.dart';
import '../../pagos/dominio/enum_metodo_pago.dart';

class ModeloTurno {
  const ModeloTurno({
    required this.id,
    required this.barberiaId,
    required this.sucursalId,
    required this.barberoId,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.servicioNombre,
    this.servicioId,
    required this.montoTotal,
    required this.estado,
    this.metodoPrecobrado,
    this.creadoEn,
    this.numero,
    DateTime? horaLlegada,
  }) : horaLlegada = horaLlegada ?? creadoEn;

  final String id;
  final String barberiaId;
  final String sucursalId;
  final String barberoId;
  final String clienteNombre;
  final String? clienteTelefono;
  final String servicioNombre;

  /// ID del servicio (para calcular duración en disponibilidad_barbero).
  final String? servicioId;
  final double montoTotal;
  final EstadoTurno estado;
  final MetodoPago? metodoPrecobrado;
  final DateTime? creadoEn;

  /// Número de turno dentro del día (para mostrar en UI).
  final int? numero;

  /// Hora de llegada del cliente. Si no está, usa la hora de creación.
  final DateTime? horaLlegada;

  /// Alias de [id] para compatibilidad con widgets de agenda.
  String get citaId => id;

  /// Monto precobrado del turno (si aplica).
  double? get montoPrecobrado => metodoPrecobrado != null ? montoTotal : null;


  factory ModeloTurno.desdeJson(Map<String, dynamic> json) {
    final creadoEnRaw = json['creado_en'];
    final creadoEn = creadoEnRaw == null
        ? null
        : DateTime.tryParse(creadoEnRaw as String);
    final horaLlegadaRaw = json['hora_llegada'];
    final horaLlegada = horaLlegadaRaw == null
        ? null
        : DateTime.tryParse(horaLlegadaRaw as String);
    return ModeloTurno(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      sucursalId: json['sucursal_id'] as String? ?? '',
      barberoId: json['barbero_id'] as String? ?? '',
      clienteNombre: (json['cliente_nombre'] ?? json['nombre_cliente']) as String? ?? 'Cliente',
      clienteTelefono: json['cliente_telefono'] as String?,
      servicioNombre: (json['servicio_nombre'] ?? json['nombre_servicio']) as String? ?? 'Servicio',
      servicioId: json['servicio_id'] as String?,
      montoTotal: (json['monto_total'] as num? ?? 0).toDouble(),
      estado: EstadoTurno.desdeTexto(json['estado'] as String? ?? ''),
      metodoPrecobrado: json['metodo_precobrado'] == null
          ? null
          : MetodoPago.desdeTexto(json['metodo_precobrado'] as String? ?? ''),
      creadoEn: creadoEn,
      numero: json['numero'] as int?,
      horaLlegada: horaLlegada ?? creadoEn,
    );
  }
}
