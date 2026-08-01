class ModeloVersionApp {
  const ModeloVersionApp({
    required this.version,
    required this.urlApk,
    this.notasCambios,
    required this.obligatoria,
  });

  final String version;
  final String urlApk;
  final String? notasCambios;
  final bool obligatoria;

  factory ModeloVersionApp.desdeJson(Map<String, dynamic> json) {
    return ModeloVersionApp(
      version: json['version'] as String,
      urlApk: json['url_apk'] as String,
      notasCambios: json['notas_cambios'] as String?,
      obligatoria: json['obligatoria'] as bool,
    );
  }
}
