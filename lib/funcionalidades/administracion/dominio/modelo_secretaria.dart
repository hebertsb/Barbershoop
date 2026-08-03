class ModeloSecretaria {
  const ModeloSecretaria({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    required this.email,
    this.sucursalId,
    this.activo = true,
    this.perfilId,
  });

  final String id;
  final String barberiaId;
  final String nombre;
  final String email;
  final String? sucursalId;
  final bool activo;
  final String? perfilId;

  factory ModeloSecretaria.desdeJson(Map<String, dynamic> json) {
    return ModeloSecretaria(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Secretaria',
      email: json['email'] as String? ?? '',
      sucursalId: json['sucursal_id'] as String?,
      activo: json['activo'] as bool? ?? true,
      perfilId: (json['perfil_id'] ?? json['id']) as String?,
    );
  }
}
