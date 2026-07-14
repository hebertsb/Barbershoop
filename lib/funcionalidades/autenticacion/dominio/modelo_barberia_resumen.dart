class ModeloBarberiaResumen {
  const ModeloBarberiaResumen({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory ModeloBarberiaResumen.desdeJson(Map<String, dynamic> json) {
    return ModeloBarberiaResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }
}
