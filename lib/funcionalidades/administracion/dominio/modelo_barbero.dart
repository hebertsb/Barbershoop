class ModeloBarbero {
  const ModeloBarbero({
    required this.id,
    required this.perfilId,
    required this.sucursalId,
    required this.barberiaId,
    required this.especialidades,
    required this.activo,
    this.nombrePerfil,
    this.urlFotoPerfil,
    this.emailPerfil,
  });

  final String id;
  final String perfilId;
  final String sucursalId;
  final String barberiaId;
  final List<String> especialidades;
  final bool activo;

  // Campos informativos obtenidos a través de un JOIN con la tabla perfiles
  final String? nombrePerfil;
  final String? urlFotoPerfil;
  final String? emailPerfil;

  factory ModeloBarbero.desdeJson(Map<String, dynamic> json) {
    final perfilJson = json['perfiles'] as Map<String, dynamic>?;
    return ModeloBarbero(
      id: json['id'] as String,
      perfilId: json['perfil_id'] as String,
      sucursalId: json['sucursal_id'] as String,
      barberiaId: json['barberia_id'] as String,
      especialidades: List<String>.from(json['especialidades'] as Iterable? ?? []),
      activo: json['activo'] as bool,
      nombrePerfil: (perfilJson?['nombre'] ?? json['nombre_perfil']) as String?,
      urlFotoPerfil: (perfilJson?['url_foto'] ?? json['url_foto_perfil']) as String?,
      emailPerfil: (perfilJson?['email'] ?? json['email_perfil']) as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'perfil_id': perfilId,
      'sucursal_id': sucursalId,
      'barberia_id': barberiaId,
      'especialidades': especialidades,
      'activo': activo,
      if (nombrePerfil != null) 'nombre_perfil': nombrePerfil,
      if (urlFotoPerfil != null) 'url_foto_perfil': urlFotoPerfil,
      if (emailPerfil != null) 'email_perfil': emailPerfil,
    };
  }

  ModeloBarbero copyWith({
    String? sucursalId,
    List<String>? especialidades,
    bool? activo,
    String? nombrePerfil,
    String? urlFotoPerfil,
    String? emailPerfil,
  }) {
    return ModeloBarbero(
      id: id,
      perfilId: perfilId,
      sucursalId: sucursalId ?? this.sucursalId,
      barberiaId: barberiaId,
      especialidades: especialidades ?? this.especialidades,
      activo: activo ?? this.activo,
      nombrePerfil: nombrePerfil ?? this.nombrePerfil,
      urlFotoPerfil: urlFotoPerfil ?? this.urlFotoPerfil,
      emailPerfil: emailPerfil ?? this.emailPerfil,
    );
  }
}
