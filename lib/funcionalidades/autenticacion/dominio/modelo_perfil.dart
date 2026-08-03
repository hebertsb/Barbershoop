import 'enum_rol_usuario.dart';

class ModeloPerfil {
  const ModeloPerfil({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    this.barberiaId,
    this.sucursalId,
    this.telefono,
    String? fotoUrl,
    String? urlFoto,
  }) : _fotoUrl = fotoUrl ?? urlFoto;

  final String id;
  final String email;
  final String nombre;
  final RolUsuario rol;
  final String? barberiaId;
  final String? sucursalId;
  final String? telefono;
  final String? _fotoUrl;

  String? get fotoUrl => _fotoUrl;
  String? get urlFoto => _fotoUrl;

  factory ModeloPerfil.desdeJson(Map<String, dynamic> json) {
    return ModeloPerfil(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      rol: RolUsuario.desdeTexto(json['rol'] as String? ?? ''),
      barberiaId: json['barberia_id'] as String?,
      sucursalId: json['sucursal_id'] as String?,
      telefono: json['telefono'] as String?,
      fotoUrl: (json['foto_url'] ?? json['url_foto']) as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'rol': rol.name,
      'barberia_id': barberiaId,
      'sucursal_id': sucursalId,
      'telefono': telefono,
      'foto_url': _fotoUrl,
    };
  }

  ModeloPerfil copyWith({
    String? id,
    String? email,
    String? nombre,
    RolUsuario? rol,
    String? barberiaId,
    String? sucursalId,
    String? telefono,
    String? fotoUrl,
    String? urlFoto,
  }) {
    return ModeloPerfil(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      barberiaId: barberiaId ?? this.barberiaId,
      sucursalId: sucursalId ?? this.sucursalId,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? urlFoto ?? _fotoUrl,
    );
  }
}
