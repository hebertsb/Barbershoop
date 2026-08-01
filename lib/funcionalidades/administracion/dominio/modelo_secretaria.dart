class ModeloSecretaria {
  const ModeloSecretaria({
    required this.perfilId,
    this.nombre,
    this.email,
    this.sucursalId,
  });

  final String perfilId;
  final String? nombre;
  final String? email;
  final String? sucursalId;

  factory ModeloSecretaria.desdeJson(Map<String, dynamic> json) {
    return ModeloSecretaria(
      perfilId: json['id'] as String,
      nombre: json['nombre'] as String?,
      email: json['email'] as String?,
      sucursalId: json['sucursal_id'] as String?,
    );
  }
}
