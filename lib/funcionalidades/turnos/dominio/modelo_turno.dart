import '../../pagos/dominio/enum_metodo_pago.dart';
import 'enum_estado_turno.dart';

class ModeloTurno {
  const ModeloTurno({
    required this.id,
    required this.barberiaId,
    required this.sucursalId,
    required this.numero,
    this.clienteId,
    this.clienteWalkinId,
    required this.servicioId,
    this.barberoId,
    required this.estado,
    this.citaId,
    required this.horaLlegada,
    this.horaAtencion,
    this.horaCompletado,
    this.montoPrecobrado,
    this.metodoPrecobrado,
  });

  final String id;
  final String barberiaId;
  final String sucursalId;
  final int numero;
  final String? clienteId;
  final String? clienteWalkinId;
  final String servicioId;
  final String? barberoId;
  final EstadoTurno estado;
  final String? citaId;
  final DateTime horaLlegada;
  final DateTime? horaAtencion;
  final DateTime? horaCompletado;
  final double? montoPrecobrado;
  final MetodoPago? metodoPrecobrado;

  factory ModeloTurno.desdeJson(Map<String, dynamic> json) {
    return ModeloTurno(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      sucursalId: json['sucursal_id'] as String,
      numero: json['numero'] as int,
      clienteId: json['cliente_id'] as String?,
      clienteWalkinId: json['cliente_walkin_id'] as String?,
      servicioId: json['servicio_id'] as String,
      barberoId: json['barbero_id'] as String?,
      estado: EstadoTurno.desdeTexto(json['estado'] as String),
      citaId: json['cita_id'] as String?,
      horaLlegada: DateTime.parse(json['hora_llegada'] as String),
      horaAtencion: json['hora_atencion'] != null
          ? DateTime.parse(json['hora_atencion'] as String)
          : null,
      horaCompletado: json['hora_completado'] != null
          ? DateTime.parse(json['hora_completado'] as String)
          : null,
      montoPrecobrado: (json['monto_precobrado'] as num?)?.toDouble(),
      metodoPrecobrado: json['metodo_precobrado'] != null
          ? MetodoPago.desdeTexto(json['metodo_precobrado'] as String)
          : null,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'sucursal_id': sucursalId,
      'numero': numero,
      'cliente_id': clienteId,
      'cliente_walkin_id': clienteWalkinId,
      'servicio_id': servicioId,
      'barbero_id': barberoId,
      'estado': estado.aTexto(),
      'cita_id': citaId,
      'hora_llegada': horaLlegada.toIso8601String(),
      'hora_atencion': horaAtencion?.toIso8601String(),
      'hora_completado': horaCompletado?.toIso8601String(),
      'monto_precobrado': montoPrecobrado,
      'metodo_precobrado': metodoPrecobrado?.aTexto(),
    };
  }

  ModeloTurno copyWith({
    String? barberoId,
    EstadoTurno? estado,
    String? citaId,
    DateTime? horaAtencion,
    DateTime? horaCompletado,
  }) {
    return ModeloTurno(
      id: id,
      barberiaId: barberiaId,
      sucursalId: sucursalId,
      numero: numero,
      clienteId: clienteId,
      clienteWalkinId: clienteWalkinId,
      servicioId: servicioId,
      barberoId: barberoId ?? this.barberoId,
      estado: estado ?? this.estado,
      citaId: citaId ?? this.citaId,
      horaLlegada: horaLlegada,
      horaAtencion: horaAtencion ?? this.horaAtencion,
      horaCompletado: horaCompletado ?? this.horaCompletado,
      montoPrecobrado: montoPrecobrado,
      metodoPrecobrado: metodoPrecobrado,
    );
  }
}
