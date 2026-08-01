class ModeloIngresoPorMetodo {
  const ModeloIngresoPorMetodo({required this.metodo, required this.monto});

  final String metodo;
  final double monto;

  factory ModeloIngresoPorMetodo.desdeJson(Map<String, dynamic> json) {
    return ModeloIngresoPorMetodo(
      metodo: json['metodo'] as String,
      monto: (json['monto'] as num).toDouble(),
    );
  }
}
