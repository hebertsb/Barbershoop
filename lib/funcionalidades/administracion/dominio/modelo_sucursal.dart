class ModeloSucursal {
  const ModeloSucursal({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.latitud,
    this.longitud,
    this.activo = true,
    this.horarioApertura,
    this.horarioCierre,
    this.managerNombre,
    this.fotoUrl,
    String? urlImagen,
  }) : _urlImagenAlias = urlImagen;

  final String id;
  final String barberiaId;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final double? latitud;
  final double? longitud;
  final bool activo;
  final String? horarioApertura;
  final String? horarioCierre;
  final String? managerNombre;
  final String? fotoUrl;
  final String? _urlImagenAlias;

  String? get urlImagen => _urlImagenAlias ?? fotoUrl;

  factory ModeloSucursal.desdeJson(Map<String, dynamic> json) {
    return ModeloSucursal(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sucursal',
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      activo: json['activo'] as bool? ?? true,
      horarioApertura: (json['horario_apertura'] ?? json['hora_apertura']) as String?,
      horarioCierre: (json['horario_cierre'] ?? json['hora_cierre']) as String?,
      managerNombre: (json['manager_nombre'] ?? json['encargado_nombre']) as String?,
      fotoUrl: (json['foto_url'] ?? json['url_imagen']) as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'latitud': latitud,
      'longitud': longitud,
      'activo': activo,
      'horario_apertura': horarioApertura,
      'horario_cierre': horarioCierre,
      'manager_nombre': managerNombre,
      'foto_url': urlImagen,
    };
  }
}
