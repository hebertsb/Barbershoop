/// Programa de fidelidad que premia a los clientes por acumular citas.
class ModeloProgramaFidelidad {
  ModeloProgramaFidelidad({
    required this.id,
    required this.barberiaId,
    String? nombre,
    String? titulo,
    int? sellosRequeridos,
    int? metaCitas,
    String? recompensa,
    this.activo = true,
    this.fechaInicio,
    this.fechaFin,
    this.descripcion,
    this.servicioId,
    List<String>? serviciosIds,
  })  : nombre = nombre ?? titulo ?? 'Programa Fidelidad',
        sellosRequeridos = sellosRequeridos ?? metaCitas ?? 10,
        recompensa = recompensa ?? 'Corte gratis',
        serviciosIdsCache = serviciosIds ?? (servicioId != null ? [servicioId] : const []);

  final String id;
  final String barberiaId;
  final String nombre;
  final int sellosRequeridos;
  final String recompensa;
  final bool activo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? descripcion;
  final String? servicioId;
  final List<String> serviciosIdsCache;

  // ── Getters alias para compatibilidad con la UI ──────────────────────────

  /// Alias de [nombre].
  String get titulo => nombre;

  /// Cantidad de citas meta: alias de [sellosRequeridos].
  int get metaCitas => sellosRequeridos;

  /// IDs de servicios aplicables.
  List<String> get serviciosIds => serviciosIdsCache;

  factory ModeloProgramaFidelidad.desdeJson(Map<String, dynamic> json) {
    final sId = json['servicio_id'] as String?;
    final sIds = (json['servicios_ids'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    return ModeloProgramaFidelidad(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: (json['nombre'] ?? json['titulo']) as String? ?? 'Programa Fidelidad',
      sellosRequeridos: (json['sellos_requeridos'] ?? json['meta_citas']) as int? ?? 10,
      recompensa: json['recompensa'] as String? ?? 'Corte gratis',
      activo: json['activo'] as bool? ?? true,
      fechaInicio: json['fecha_inicio'] == null
          ? null
          : DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] == null
          ? null
          : DateTime.parse(json['fecha_fin'] as String),
      descripcion: json['descripcion'] as String?,
      servicioId: sId,
      serviciosIds: sIds ?? (sId != null ? [sId] : const []),
    );
  }

  Map<String, dynamic> aJson() {
    final sIds = serviciosIdsCache.isNotEmpty
        ? serviciosIdsCache
        : (servicioId != null ? [servicioId!] : <String>[]);
    final mapa = <String, dynamic>{
      'barberia_id': barberiaId,
      'titulo': nombre,
      'meta_citas': sellosRequeridos,
      'servicios_ids': sIds,
      'activo': activo,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String().substring(0, 10),
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().substring(0, 10),
    };

    if (id.trim().isNotEmpty) {
      mapa['id'] = id;
    }

    return mapa;
  }
}
