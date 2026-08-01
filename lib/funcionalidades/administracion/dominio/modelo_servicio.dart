class ModeloServicio {
  const ModeloServicio({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.descripcion,
    required this.duracionMin,
    required this.precio,
    required this.activo,
    this.urlImagen,
  });

  final String id;
  final String barberiaId;
  final String nombre;
  final String? descripcion;
  final int duracionMin;
  final double precio;
  final bool activo;
  final String? urlImagen;

  factory ModeloServicio.desdeJson(Map<String, dynamic> json) {
    return ModeloServicio(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      duracionMin: json['duracion_min'] as int,
      precio: (json['precio'] as num).toDouble(),
      activo: json['activo'] as bool,
      urlImagen: json['url_imagen'] as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'duracion_min': duracionMin,
      'precio': precio,
      'activo': activo,
      'url_imagen': urlImagen,
    };
  }

  ModeloServicio copyWith({
    String? nombre,
    String? descripcion,
    int? duracionMin,
    double? precio,
    bool? activo,
    String? urlImagen,
  }) {
    return ModeloServicio(
      id: id,
      barberiaId: barberiaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      duracionMin: duracionMin ?? this.duracionMin,
      precio: precio ?? this.precio,
      activo: activo ?? this.activo,
      urlImagen: urlImagen ?? this.urlImagen,
    );
  }
}
