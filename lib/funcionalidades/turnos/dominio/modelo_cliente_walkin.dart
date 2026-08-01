class ModeloClienteWalkin {
  const ModeloClienteWalkin({
    required this.id,
    required this.nombre,
    required this.telefono,
  });

  final String id;
  final String nombre;
  final String telefono;

  factory ModeloClienteWalkin.desdeJson(Map<String, dynamic> json) {
    return ModeloClienteWalkin(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
    );
  }
}
