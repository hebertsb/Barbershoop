class ModeloMarcaBarberia {
  const ModeloMarcaBarberia({
    required this.nombre,
    this.slogan,
    this.urlLogo,
    this.colorAcentoHex,
  });

  final String nombre;
  final String? slogan;
  final String? urlLogo;
  final String? colorAcentoHex;

  factory ModeloMarcaBarberia.desdeJson(Map<String, dynamic> json) {
    return ModeloMarcaBarberia(
      nombre: json['nombre'] as String,
      slogan: json['slogan'] as String?,
      urlLogo: json['url_logo'] as String?,
      colorAcentoHex: json['color_acento_hex'] as String?,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'nombre': nombre,
      'slogan': slogan,
      'url_logo': urlLogo,
      'color_acento_hex': colorAcentoHex,
    };
  }
}
