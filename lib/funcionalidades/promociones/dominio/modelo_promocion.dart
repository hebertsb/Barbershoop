import 'enum_tipo_descuento.dart';

class ModeloPromocion {
  const ModeloPromocion({
    required this.id,
    required this.barberiaId,
    required this.servicioId,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.tipoDescuento,
    required this.descuento,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
    this.nombreServicio,
    this.limiteUsosPorCliente,
    this.capacidadMaxima,
    this.serviciosIds,
    this.nombresServiciosCombo,
    this.clienteExclusivoId,
  });

  final String id;
  final String barberiaId;
  final String? servicioId;
  final String titulo;
  final String? descripcion;
  final String? imagen;
  final TipoDescuento tipoDescuento;
  final double descuento;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;

  /// Viene de un embed de Supabase (`servicios.nombre`), solo presente
  /// cuando el repositorio lo pide explícitamente.
  final String? nombreServicio;

  final int? limiteUsosPorCliente;
  final int? capacidadMaxima;

  /// Combo de 2+ servicios (jsonb) -- alternativa a [servicioId] cuando la
  /// promo aplica a varios servicios juntos.
  final List<String>? serviciosIds;
  final List<String>? nombresServiciosCombo;

  /// Premio de fidelidad: promoción reusada como cupón de un solo cliente.
  final String? clienteExclusivoId;

  bool get estaVigente {
    if (!activo) return false;
    final hoy = DateTime.now();
    if (fechaInicio != null && hoy.isBefore(fechaInicio!)) return false;
    if (fechaFin != null && hoy.isAfter(fechaFin!)) return false;
    return true;
  }

  double calcularDescuento(double precioBase) {
    final monto = tipoDescuento == TipoDescuento.porcentaje
        ? precioBase * (descuento / 100)
        : descuento;
    return monto > precioBase ? precioBase : monto;
  }

  double calcularPrecioFinal(double precioBase) {
    return precioBase - calcularDescuento(precioBase);
  }

  factory ModeloPromocion.desdeJson(Map<String, dynamic> json) {
    final serviciosJson = json['servicios'] as Map<String, dynamic>?;
    return ModeloPromocion(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      servicioId: json['servicio_id'] as String?,
      nombreServicio: serviciosJson?['nombre'] as String?,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      imagen: json['imagen'] as String?,
      tipoDescuento: TipoDescuento.desdeTexto(json['tipo_descuento'] as String),
      descuento: (json['descuento'] as num).toDouble(),
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      activo: json['activo'] as bool,
      limiteUsosPorCliente: json['limite_usos_por_cliente'] as int?,
      capacidadMaxima: json['capacidad_maxima'] as int?,
      serviciosIds: (json['servicios_ids'] as List?)?.cast<String>(),
      nombresServiciosCombo:
          (json['nombres_servicios'] as List?)?.cast<String>(),
      clienteExclusivoId: json['cliente_exclusivo_id'] as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'servicio_id': servicioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'tipo_descuento': tipoDescuento.aTexto(),
      'descuento': descuento,
      'fecha_inicio': fechaInicio?.toIso8601String().split('T').first,
      'fecha_fin': fechaFin?.toIso8601String().split('T').first,
      'activo': activo,
      'limite_usos_por_cliente': limiteUsosPorCliente,
      'capacidad_maxima': capacidadMaxima,
      if (serviciosIds != null) 'servicios_ids': serviciosIds,
      if (nombresServiciosCombo != null)
        'nombres_servicios': nombresServiciosCombo,
      if (clienteExclusivoId != null)
        'cliente_exclusivo_id': clienteExclusivoId,
    };
  }

  ModeloPromocion copyWith({
    String? servicioId,
    String? titulo,
    String? descripcion,
    String? imagen,
    TipoDescuento? tipoDescuento,
    double? descuento,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activo,
    int? limiteUsosPorCliente,
    int? capacidadMaxima,
    List<String>? serviciosIds,
    List<String>? nombresServiciosCombo,
  }) {
    return ModeloPromocion(
      id: id,
      barberiaId: barberiaId,
      servicioId: servicioId ?? this.servicioId,
      nombreServicio: nombreServicio,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      tipoDescuento: tipoDescuento ?? this.tipoDescuento,
      descuento: descuento ?? this.descuento,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activo: activo ?? this.activo,
      limiteUsosPorCliente: limiteUsosPorCliente ?? this.limiteUsosPorCliente,
      capacidadMaxima: capacidadMaxima ?? this.capacidadMaxima,
      serviciosIds: serviciosIds ?? this.serviciosIds,
      nombresServiciosCombo:
          nombresServiciosCombo ?? this.nombresServiciosCombo,
      clienteExclusivoId: clienteExclusivoId,
    );
  }
}
