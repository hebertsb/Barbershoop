import '../../../../nucleo/utilidades/parsear_fecha_utc.dart';
import 'enum_estado_cita.dart';

class ModeloCita {
  const ModeloCita({
    required this.id,
    required this.barberiaId,
    required this.clienteId,
    required this.barberoId,
    required this.servicioId,
    required this.fecha,
    required this.estado,
    this.sucursalId,
    this.precioTotal = 0,
    this.notas,
    this.duracionMin = 30,
    this.nombreClienteCache,
    this.telefonoClienteCache,
    this.precioCobrado,
    this.serviciosCombo = const [],
  });

  final String id;
  final String barberiaId;
  final String clienteId;
  final String barberoId;
  final String servicioId;
  final DateTime fecha;
  final EstadoCita estado;
  final String? sucursalId;
  final double precioTotal;
  final String? notas;

  /// Duración estimada del servicio en minutos.
  final int duracionMin;

  /// Nombre del cliente si viene en el join del repositorio.
  final String? nombreClienteCache;

  /// Teléfono del cliente si viene en el join.
  final String? telefonoClienteCache;

  /// Precio cobrado real.
  final double? precioCobrado;

  /// Lista de nombres de servicios si es una cita combo.
  final List<String> serviciosCombo;

  // ── Getters alias ────────────────────────────────────────────────────────

  DateTime get fechaHora => fecha;
  DateTime get fechaInicio => fecha;

  /// Retorna si la cita aún se puede reprogramar.
  bool puedeReprogramarse([int? minutosCancelacion]) {
    if (estado != EstadoCita.pendiente && estado != EstadoCita.confirmada) {
      return false;
    }
    if (minutosCancelacion == null) return true;
    final limite = fecha.subtract(Duration(minutes: minutosCancelacion));
    return DateTime.now().isBefore(limite);
  }


  /// Nombre del cliente para mostrar en la UI.
  String? get nombreCliente => nombreClienteCache;

  /// Teléfono del cliente para contactar por WhatsApp.
  String? get telefonoCliente => telefonoClienteCache;

  /// Nombres de servicios combo.
  List<String> get nombresServiciosCombo => serviciosCombo;

  factory ModeloCita.desdeJson(Map<String, dynamic> json) {
    final fechaRaw = json['fecha'] ?? json['fecha_hora'];
    return ModeloCita(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      clienteId: json['cliente_id'] as String? ?? '',
      barberoId: json['barbero_id'] as String? ?? '',
      servicioId: json['servicio_id'] as String? ?? '',
      fecha: parsearFechaUtc(fechaRaw as String?),
      estado: EstadoCita.desdeTexto(json['estado'] as String? ?? ''),
      sucursalId: json['sucursal_id'] as String?,
      precioTotal: (json['precio_total'] as num? ?? 0).toDouble(),
      notas: json['notas'] as String?,
      duracionMin: json['duracion_min'] as int? ?? 30,
      nombreClienteCache: (json['cliente_nombre'] ?? json['nombre_cliente']) as String?,
      telefonoClienteCache: (json['cliente_telefono'] ?? json['telefono_cliente']) as String?,
      precioCobrado: (json['precio_cobrado'] as num?)?.toDouble(),
      serviciosCombo: (json['servicios_combo'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
