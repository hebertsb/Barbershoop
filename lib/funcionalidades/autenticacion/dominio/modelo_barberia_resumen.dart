class ModeloBarberiaResumen {
  const ModeloBarberiaResumen({
    required this.id,
    required this.nombre,
    this.logoUrl,
  });

  final String id;
  final String nombre;
  final String? logoUrl;

  factory ModeloBarberiaResumen.desdeJson(Map<String, dynamic> json) {
    return ModeloBarberiaResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}
