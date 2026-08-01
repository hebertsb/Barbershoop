import 'enum_estado_cita.dart';

class ModeloCita {
  const ModeloCita({
    required this.id,
    required this.barberiaId,
    required this.sucursalId,
    required this.barberoId,
    this.clienteId,
    this.clienteWalkinId,
    required this.servicioId,
    required this.fechaHora,
    required this.duracionMin,
    required this.estado,
    this.precioCobrado,
    this.completadoPor,
    this.canceladoPor,
    this.nombreCliente,
    this.telefonoCliente,
    this.nombresServiciosCombo = const [],
  });

  final String id;
  final String barberiaId;
  final String sucursalId;
  final String barberoId;
  final String? clienteId;
  final String? clienteWalkinId;
  final String servicioId;
  final DateTime fechaHora;
  final int duracionMin;
  final EstadoCita estado;
  final double? precioCobrado;

  /// Quién dejó la cita en cada estado final (auditoría remota) -- `null`
  /// si lo hizo un cron automático o si la cita sigue activa.
  final String? completadoPor;
  final String? canceladoPor;

  // Campos informativos obtenidos vía JOIN, solo presentes cuando el
  // repositorio los pide explícitamente.
  final String? nombreCliente;
  final String? telefonoCliente;

  /// `citas.servicio_id` solo guarda el primer servicio de un combo -- si la
  /// cita viene de una promoción combo, este embed trae los nombres
  /// completos. Vacío = no es un combo, usar el catálogo con [servicioId].
  final List<String> nombresServiciosCombo;

  /// `true` si faltan más de [minutosMinimo] para la cita -- criterio de
  /// "todavía se puede reprogramar sin romper la agenda del barbero".
  bool puedeReprogramarse(int minutosMinimo) {
    final minutosFaltantes = fechaHora.difference(DateTime.now()).inMinutes;
    return minutosFaltantes >= minutosMinimo;
  }

  factory ModeloCita.desdeJson(Map<String, dynamic> json) {
    final perfilJson = json['perfiles'] as Map<String, dynamic>?;
    final promoJson = json['promociones'] as Map<String, dynamic>?;
    final nombresServiciosRaw = promoJson?['nombres_servicios'];
    final nombresServiciosCombo = (nombresServiciosRaw is List)
        ? nombresServiciosRaw.cast<String>()
        : const <String>[];

    return ModeloCita(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      sucursalId: json['sucursal_id'] as String,
      barberoId: json['barbero_id'] as String,
      clienteId: json['cliente_id'] as String?,
      clienteWalkinId: json['cliente_walkin_id'] as String?,
      servicioId: json['servicio_id'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      duracionMin: json['duracion_min'] as int,
      estado: EstadoCita.desdeTexto(json['estado'] as String),
      precioCobrado: (json['precio_cobrado'] as num?)?.toDouble(),
      completadoPor: json['completado_por'] as String?,
      canceladoPor: json['cancelado_por'] as String?,
      nombreCliente: (perfilJson?['nombre']) as String?,
      telefonoCliente: (perfilJson?['telefono']) as String?,
      nombresServiciosCombo: nombresServiciosCombo,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'sucursal_id': sucursalId,
      'barbero_id': barberoId,
      'cliente_id': clienteId,
      'cliente_walkin_id': clienteWalkinId,
      'servicio_id': servicioId,
      'fecha_hora': fechaHora.toIso8601String(),
      'duracion_min': duracionMin,
      'estado': estado.aTexto(),
      'precio_cobrado': precioCobrado,
    };
  }

  ModeloCita copyWith({EstadoCita? estado, double? precioCobrado}) {
    return ModeloCita(
      id: id,
      barberiaId: barberiaId,
      sucursalId: sucursalId,
      barberoId: barberoId,
      clienteId: clienteId,
      clienteWalkinId: clienteWalkinId,
      servicioId: servicioId,
      fechaHora: fechaHora,
      duracionMin: duracionMin,
      estado: estado ?? this.estado,
      precioCobrado: precioCobrado ?? this.precioCobrado,
      completadoPor: completadoPor,
      canceladoPor: canceladoPor,
      nombreCliente: nombreCliente,
      telefonoCliente: telefonoCliente,
      nombresServiciosCombo: nombresServiciosCombo,
    );
  }
}
