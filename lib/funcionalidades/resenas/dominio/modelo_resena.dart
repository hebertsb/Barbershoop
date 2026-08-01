class ModeloResena {
  const ModeloResena({
    required this.id,
    required this.clienteNombre,
    required this.calificacion,
    required this.comentario,
    required this.creadoEn,
  });

  final String id;
  final String clienteNombre;
  final int calificacion;
  final String? comentario;
  final DateTime creadoEn;

  factory ModeloResena.desdeJson(Map<String, dynamic> json) {
    return ModeloResena(
      id: json['id'] as String,
      clienteNombre: json['cliente_nombre'] as String,
      calificacion: json['calificacion'] as int,
      comentario: json['comentario'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }
}
