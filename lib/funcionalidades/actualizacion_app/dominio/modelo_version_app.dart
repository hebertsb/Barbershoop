class ModeloVersionApp {
  const ModeloVersionApp({
    required this.version,
    required this.codigoConstruccion,
    required this.urlDescarga,
    required this.obligatoria,
    this.notas,
  });

  final String version;
  final int codigoConstruccion;
  final String urlDescarga;
  final bool obligatoria;
  final String? notas;

  String get urlApk => urlDescarga;
  String? get notasCambios => notas;

  factory ModeloVersionApp.desdeJson(Map<String, dynamic> json) {
    return ModeloVersionApp(
      version: json['version'] as String? ?? '1.0.0',
      codigoConstruccion: json['codigo_construccion'] as int? ?? 1,
      urlDescarga: (json['url_descarga'] ?? json['url_apk']) as String? ?? '',
      obligatoria: json['obligatoria'] as bool? ?? false,
      notas: (json['notas'] ?? json['notas_cambios']) as String?,
    );
  }
}
