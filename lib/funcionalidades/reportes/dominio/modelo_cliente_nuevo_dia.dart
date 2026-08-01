class ModeloClienteNuevoDia {
  const ModeloClienteNuevoDia({
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.horaRegistro,
  });

  final String nombre;
  final String? email;
  final String? telefono;
  final DateTime horaRegistro;

  factory ModeloClienteNuevoDia.desdeJson(Map<String, dynamic> json) {
    return ModeloClienteNuevoDia(
      nombre: json['nombre'] as String,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      horaRegistro: DateTime.parse(json['hora_registro'] as String),
    );
  }
}
