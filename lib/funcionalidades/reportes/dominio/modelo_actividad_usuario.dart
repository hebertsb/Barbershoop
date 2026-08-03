class ModeloActividadUsuario {
  const ModeloActividadUsuario({
    required this.usuarioId,
    required this.usuarioNombre,
    required this.rol,
    required this.citasCompletadas,
    required this.montoTotalCobrado,
    required this.citasCanceladas,
  });

  final String usuarioId;
  final String usuarioNombre;
  final String rol;
  final int citasCompletadas;
  final double montoTotalCobrado;
  final int citasCanceladas;

  factory ModeloActividadUsuario.desdeJson(Map<String, dynamic> json) {
    return ModeloActividadUsuario(
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: json['usuario_nombre'] as String? ?? 'Usuario',
      rol: json['rol'] as String? ?? '',
      citasCompletadas: (json['citas_completadas'] as num? ?? 0).toInt(),
      montoTotalCobrado: (json['monto_total_cobrado'] as num? ?? 0).toDouble(),
      citasCanceladas: (json['citas_canceladas'] as num? ?? 0).toInt(),
    );
  }
}