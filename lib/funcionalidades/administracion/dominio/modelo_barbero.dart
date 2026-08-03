class ModeloBarbero {
  const ModeloBarbero({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.email,
    this.telefono,
    this.telefonoPerfil,
    this.fotoUrl,
    this.nivel,
    this.sucursalId,
    this.especialidades = const [],
    this.activo = true,
    this.descripcion,
    this.perfilId,
  });

  final String id;
  final String barberiaId;
  final String nombre;
  final String? email;
  final String? telefono;

  /// Teléfono público del perfil del barbero (para WhatsApp, etc.).
  final String? telefonoPerfil;
  final String? fotoUrl;
  final String? nivel;
  final String? sucursalId;
  final List<String> especialidades;
  final bool activo;

  /// Descripción pública del barbero (bio / especialidad destacada).
  final String? descripcion;

  /// ID del perfil de autenticación del barbero (tabla `perfiles`).
  final String? perfilId;

  String? get nombrePerfil => nombre;

  /// Alias de [fotoUrl] — URL de la foto de perfil del barbero.
  String? get urlFotoPerfil => fotoUrl;

  /// Alias de [email] — Email del perfil del barbero.
  String? get emailPerfil => email;

  /// Calificación promedio del barbero.
  double get calificacionPromedio => 5.0;

  /// Cantidad de reseñas/calificaciones recibidas.
  int get calificacionCantidad => 0;

  factory ModeloBarbero.desdeJson(Map<String, dynamic> json) {
    String? pNombre;
    String? pEmail;
    String? pFoto;
    final perfilData = json['perfiles'];
    if (perfilData is Map<String, dynamic>) {
      pNombre = perfilData['nombre'] as String?;
      pEmail = perfilData['email'] as String?;
      pFoto = (perfilData['url_foto'] ?? perfilData['foto_url']) as String?;
    }

    return ModeloBarbero(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: (json['nombre'] ?? json['nombre_perfil'] ?? pNombre) as String? ?? 'Barbero',
      email: (json['email'] ?? pEmail) as String?,
      telefono: json['telefono'] as String?,
      telefonoPerfil: (json['telefono_perfil'] ?? json['telefono']) as String?,
      fotoUrl: (json['foto_url'] ?? json['url_foto'] ?? pFoto) as String?,
      nivel: json['nivel'] as String?,
      sucursalId: json['sucursal_id'] as String?,
      especialidades: (json['especialidades'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      activo: json['activo'] as bool? ?? true,
      descripcion: json['descripcion'] as String?,
      perfilId: json['perfil_id'] as String?,
    );
  }

  ModeloBarbero copyWith({
    String? id,
    String? barberiaId,
    String? nombre,
    String? email,
    String? telefono,
    String? telefonoPerfil,
    String? fotoUrl,
    String? nivel,
    bool limpiarNivel = false,
    String? sucursalId,
    List<String>? especialidades,
    bool? activo,
    String? descripcion,
    String? perfilId,
  }) {
    return ModeloBarbero(
      id: id ?? this.id,
      barberiaId: barberiaId ?? this.barberiaId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      telefonoPerfil: telefonoPerfil ?? this.telefonoPerfil,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      nivel: limpiarNivel ? null : (nivel ?? this.nivel),
      sucursalId: sucursalId ?? this.sucursalId,
      especialidades: especialidades ?? this.especialidades,
      activo: activo ?? this.activo,
      descripcion: descripcion ?? this.descripcion,
      perfilId: perfilId ?? this.perfilId,
    );
  }
}
