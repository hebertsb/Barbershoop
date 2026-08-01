class ModeloInsumo {
  const ModeloInsumo({
    required this.id,
    required this.barberiaId,
    required this.sucursalId,
    required this.nombre,
    this.categoria,
    required this.stock,
    required this.stockMinimo,
    this.costoUnitario,
  });

  final String id;
  final String barberiaId;
  final String sucursalId;
  final String nombre;
  final String? categoria;
  final int stock;
  final int stockMinimo;
  final double? costoUnitario;

  bool get bajoMinimo => stock <= stockMinimo;

  factory ModeloInsumo.desdeJson(Map<String, dynamic> json) {
    return ModeloInsumo(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      sucursalId: json['sucursal_id'] as String,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String?,
      stock: json['stock'] as int,
      stockMinimo: json['stock_minimo'] as int,
      costoUnitario: (json['costo_unitario'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'barberia_id': barberiaId,
      'sucursal_id': sucursalId,
      'nombre': nombre,
      'categoria': categoria,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'costo_unitario': costoUnitario,
    };
  }

  ModeloInsumo copyWith({
    String? nombre,
    String? categoria,
    int? stock,
    int? stockMinimo,
    double? costoUnitario,
  }) {
    return ModeloInsumo(
      id: id,
      barberiaId: barberiaId,
      sucursalId: sucursalId,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      costoUnitario: costoUnitario ?? this.costoUnitario,
    );
  }
}
