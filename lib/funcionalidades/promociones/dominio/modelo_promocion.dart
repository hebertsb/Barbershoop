import 'enum_tipo_descuento.dart';

class ModeloPromocion {
  ModeloPromocion({
    required this.id,
    required this.barberiaId,
    required this.titulo,
    this.descripcion,
    required this.tipoDescuento,
    num? valorDescuento,
    num? descuento,
    this.sucursalId,
    List<String>? serviciosIds,
    String? servicioId,
    String? nombreServicio,
    List<String>? nombresServicios,
    this.fechaInicio,
    this.fechaFin,
    String? fotoUrlParam,
    String? fotoUrl,
    String? imagen,
    bool? activa,
    bool? activo,
    this.capacidadMaxima,
    this.limiteUsosPorCliente,
  })  : valorDescuento = (valorDescuento ?? descuento ?? 0).toDouble(),
        serviciosIds = serviciosIds ?? (servicioId != null ? [servicioId] : const []),
        fotoUrl = fotoUrlParam ?? fotoUrl ?? imagen,
        activa = activa ?? activo ?? true,
        nombresServiciosCache = nombresServicios ?? (nombreServicio != null ? [nombreServicio] : null);

  final String id;
  final String barberiaId;
  final String titulo;
  final String? descripcion;
  final TipoDescuento tipoDescuento;
  final double valorDescuento;
  final String? sucursalId;
  final List<String> serviciosIds;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? fotoUrl;
  final bool activa;
  final int? capacidadMaxima;
  final int? limiteUsosPorCliente;
  final List<String>? nombresServiciosCache;

  double get descuento => valorDescuento;
  String? get imagen => fotoUrl;
  String get etiquetaServicios => serviciosIds.isNotEmpty ? 'Válido para servicios seleccionados' : 'Válido para todos los servicios';
  String? get servicioId => serviciosIds.isNotEmpty ? serviciosIds.first : null;

  /// Alias de [activa] para compatibilidad con la UI.
  bool get activo => activa;

  /// Una promoción es un combo si aplica a más de un servicio.
  bool get esCombo => serviciosIds.length > 1;

  /// Retorna si la promoción está vigente actualmente.
  bool get estaVigente => activa && (fechaFin == null || fechaFin!.isAfter(DateTime.now()));

  factory ModeloPromocion.desdeJson(Map<String, dynamic> json) {
    final sId = json['servicio_id'] as String?;
    final sIds = (json['servicios_ids'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    return ModeloPromocion(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? 'Promoción',
      descripcion: json['descripcion'] as String?,
      tipoDescuento: TipoDescuento.desdeTexto(json['tipo_descuento'] as String? ?? ''),
      valorDescuento: (json['valor_descuento'] ?? json['descuento'] as num? ?? 0).toDouble(),
      sucursalId: json['sucursal_id'] as String?,
      serviciosIds: sIds ?? (sId != null ? [sId] : const []),
      fechaInicio: json['fecha_inicio'] == null
          ? null
          : DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] == null
          ? null
          : DateTime.parse(json['fecha_fin'] as String),
      fotoUrl: (json['foto_url'] ?? json['imagen']) as String?,
      activa: json['activa'] as bool? ?? json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> aJson() {
    final mapa = <String, dynamic>{
      'barberia_id': barberiaId,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo_descuento': tipoDescuento == TipoDescuento.porcentaje ? 'porcentaje' : 'monto_fijo',
      'descuento': valorDescuento,
      if (servicioId != null && servicioId!.isNotEmpty) 'servicio_id': servicioId,
      'fecha_inicio': fechaInicio?.toIso8601String().substring(0, 10),
      'fecha_fin': fechaFin?.toIso8601String().substring(0, 10),
      'imagen': fotoUrl,
      'activo': activa,
    };

    if (id.trim().isNotEmpty) {
      mapa['id'] = id;
    }

    return mapa;
  }

  ModeloPromocion copyWith({
    String? id,
    String? barberiaId,
    String? titulo,
    String? descripcion,
    TipoDescuento? tipoDescuento,
    double? valorDescuento,
    String? sucursalId,
    List<String>? serviciosIds,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? fotoUrl,
    bool? activa,
    bool? activo,
    int? capacidadMaxima,
    int? limiteUsosPorCliente,
  }) {
    return ModeloPromocion(
      id: id ?? this.id,
      barberiaId: barberiaId ?? this.barberiaId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipoDescuento: tipoDescuento ?? this.tipoDescuento,
      valorDescuento: valorDescuento ?? this.valorDescuento,
      sucursalId: sucursalId ?? this.sucursalId,
      serviciosIds: serviciosIds ?? this.serviciosIds,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      activa: activa ?? activo ?? this.activa,
      capacidadMaxima: capacidadMaxima ?? this.capacidadMaxima,
      limiteUsosPorCliente:
          limiteUsosPorCliente ?? this.limiteUsosPorCliente,
    );
  }
}
