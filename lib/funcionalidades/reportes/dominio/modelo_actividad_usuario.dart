class ModeloActividadUsuario {
  const ModeloActividadUsuario({
    required this.usuarioId,
    required this.usuarioNombre,
    required this.citasCompletadas,
    required this.citasCanceladas,
  });

  final String usuarioId;
  final String usuarioNombre;
  final int citasCompletadas;
  final int citasCanceladas;

  factory ModeloActividadUsuario.desdeJson(Map<String, dynamic> json) {
    return ModeloActividadUsuario(
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: json['usuario_nombre'] as String,
      citasCompletadas: json['citas_completadas'] as int,
      citasCanceladas: json['citas_canceladas'] as int,
    );
  }
}
