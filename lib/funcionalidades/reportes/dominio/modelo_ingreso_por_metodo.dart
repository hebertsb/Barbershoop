class ModeloIngresoPorMetodo {
  const ModeloIngresoPorMetodo({
    required this.metodo,
    required this.montoTotal,
    required this.cantidadPagos,
  });

  final String metodo;
  final double montoTotal;
  final int cantidadPagos;

  factory ModeloIngresoPorMetodo.desdeJson(Map<String, dynamic> json) {
    return ModeloIngresoPorMetodo(
      metodo: json['metodo'] as String,
      montoTotal: (json['monto_total'] as num? ?? 0).toDouble(),
      cantidadPagos: (json['cantidad_pagos'] as num? ?? 0).toInt(),
    );
  }
}