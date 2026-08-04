class ModeloServicio {
  ModeloServicio({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    int? duracionMinutos,
    int? duracionMin,
    this.sucursalId,
    this.fotoUrl,
    String? urlImagen,
    this.activo = true,
  })  : duracionMinutos = duracionMinutos ?? duracionMin ?? 30,
        _urlImagenAlias = urlImagen;

  final String id;
  final String barberiaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int duracionMinutos;
  final String? sucursalId;
  final String? fotoUrl;
  final String? _urlImagenAlias;
  final bool activo;

  int get duracionMin => duracionMinutos;
  String? get urlImagen => _urlImagenAlias ?? fotoUrl;

  factory ModeloServicio.desdeJson(Map<String, dynamic> json) {
    return ModeloServicio(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Servicio',
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num? ?? 0).toDouble(),
      duracionMinutos: (json['duracion_minutos'] ?? json['duracion_min']) as int? ?? 30,
      sucursalId: json['sucursal_id'] as String?,
      fotoUrl: (json['foto_url'] ?? json['url_imagen']) as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> aJson() {
    final mapa = <String, dynamic>{
      'barberia_id': barberiaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'duracion_minutos': duracionMinutos,
      'sucursal_id': sucursalId,
      'foto_url': urlImagen,
      'url_imagen': urlImagen,
      'activo': activo,
    };

    if (id.trim().isNotEmpty) {
      mapa['id'] = id;
    }

    return mapa;
  }
}
