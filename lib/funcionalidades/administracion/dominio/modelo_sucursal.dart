class ModeloSucursal {
  const ModeloSucursal({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.horarioApertura,
    this.horarioCierre,
    required this.activo,
  });

  final String id;
  final String barberiaId;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? horarioApertura;
  final String? horarioCierre;
  final bool activo;

  factory ModeloSucursal.desdeJson(Map<String, dynamic> json) {
    // Normalizar formato de hora (la DB devuelve "HH:MM:SS") a "HH:MM",
    // igual que ModeloHorarioBarbero, para que el formulario no lo reconstruya con
    // segundos duplicados al editar sin volver a tocar el selector de hora.
    String? normalizarHora(String? hora) {
      if (hora == null) return null;
      final partes = hora.split(':');
      if (partes.length >= 2) {
        return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';
      }
      return hora;
    }

    return ModeloSucursal(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      horarioApertura: normalizarHora(json['horario_apertura'] as String?),
      horarioCierre: normalizarHora(json['horario_cierre'] as String?),
      activo: json['activo'] as bool,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'horario_apertura': horarioApertura,
      'horario_cierre': horarioCierre,
      'activo': activo,
    };
  }

  ModeloSucursal copyWith({
    String? nombre,
    String? direccion,
    String? telefono,
    String? horarioApertura,
    String? horarioCierre,
    bool? activo,
  }) {
    return ModeloSucursal(
      id: id,
      barberiaId: barberiaId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      horarioApertura: horarioApertura ?? this.horarioApertura,
      horarioCierre: horarioCierre ?? this.horarioCierre,
      activo: activo ?? this.activo,
    );
  }
}
