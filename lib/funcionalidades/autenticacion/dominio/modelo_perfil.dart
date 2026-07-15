import 'enum_rol_usuario.dart';

class ModeloPerfil {
  const ModeloPerfil({
    required this.id,
    required this.email,
    required this.barberiaId,
    required this.rol,
    required this.nombre,
    required this.urlFoto,
    required this.telefono,
  });

  final String id;
  final String? email;
  final String? barberiaId;
  final RolUsuario rol;
  final String? nombre;
  final String? urlFoto;
  final String? telefono;

  factory ModeloPerfil.desdeJson(Map<String, dynamic> json) {
    return ModeloPerfil(
      id: json['id'] as String,
      email: json['email'] as String?,
      barberiaId: json['barberia_id'] as String?,
      rol: RolUsuario.desdeTexto(json['rol'] as String),
      nombre: json['nombre'] as String?,
      urlFoto: json['url_foto'] as String?,
      telefono: json['telefono'] as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'email': email,
      'barberia_id': barberiaId,
      'rol': rol.name,
      'nombre': nombre,
      'url_foto': urlFoto,
      'telefono': telefono,
    };
  }

  ModeloPerfil copyWith({
    String? barberiaId,
    RolUsuario? rol,
    String? nombre,
    String? urlFoto,
    String? telefono,
  }) {
    return ModeloPerfil(
      id: id,
      email: email,
      barberiaId: barberiaId ?? this.barberiaId,
      rol: rol ?? this.rol,
      nombre: nombre ?? this.nombre,
      urlFoto: urlFoto ?? this.urlFoto,
      telefono: telefono ?? this.telefono,
    );
  }
}
