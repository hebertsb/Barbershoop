class ModeloResena {
  const ModeloResena({
    required this.id,
    required this.citaId,
    required this.barberoId,
    required this.clienteId,
    required this.calificacion,
    this.comentario,
    required this.fecha,
    this.clienteNombreCache,
  });

  final String id;
  final String citaId;
  final String barberoId;
  final String clienteId;
  final int calificacion;
  final String? comentario;
  final DateTime fecha;
  final String? clienteNombreCache;

  /// Nombre del cliente, si viene en el join del repositorio; si no, se usa
  /// el clienteId como fallback para que la UI nunca quede vacía.
  String get clienteNombre =>
      (clienteNombreCache != null && clienteNombreCache!.isNotEmpty)
          ? clienteNombreCache!
          : (clienteId.isNotEmpty ? clienteId : 'Cliente');

  /// Alias de [fecha] para compatibilidad con widgets que usan `creadoEn`.
  DateTime get creadoEn => fecha;

  factory ModeloResena.desdeJson(Map<String, dynamic> json) {
    final fechaRaw = json['fecha'] ?? json['creado_en'] ?? json['created_at'];
    DateTime fechaParsed;
    if (fechaRaw is String) {
      fechaParsed = DateTime.tryParse(fechaRaw) ?? DateTime.now();
    } else {
      fechaParsed = DateTime.now();
    }

    String? clienteNombre;
    final perfilData = json['perfiles'];
    if (perfilData is Map<String, dynamic>) {
      clienteNombre = perfilData['nombre'] as String?;
    }
    clienteNombre ??= json['cliente_nombre'] as String?;

    return ModeloResena(
      id: json['id'] as String? ?? '',
      citaId: json['cita_id'] as String? ?? '',
      barberoId: json['barbero_id'] as String? ?? '',
      clienteId: json['cliente_id'] as String? ?? '',
      calificacion: (json['calificacion'] as num? ?? 5).toInt(),
      comentario: json['comentario'] as String?,
      fecha: fechaParsed,
      clienteNombreCache: clienteNombre,
    );
  }
}
