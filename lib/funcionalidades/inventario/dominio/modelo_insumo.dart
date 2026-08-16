class ModeloInsumo {
  ModeloInsumo({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.descripcion,
    num? stockActual,
    num? stock,
    num? stockMinimo,
    this.unidadMedida = 'unidad',
    String? sucursalId,
    String? categoria,
    num? costoUnitario,
    this.activo = true,
  })  : stockActual = (stockActual ?? stock ?? 0).toDouble(),
        stockMinimo = (stockMinimo ?? 0).toDouble(),
        sucursalIdCache = sucursalId,
        categoriaCache = categoria,
        costoUnitarioCache = costoUnitario?.toDouble();

  final String id;
  final String barberiaId;
  final String nombre;
  final String? descripcion;
  final double stockActual;
  final double stockMinimo;
  final String unidadMedida;
  final String? sucursalIdCache;
  final String? categoriaCache;
  final double? costoUnitarioCache;
  final bool activo;

  /// Alias de [stockActual].
  double get stock => stockActual;

  /// Categoría del insumo.
  String? get categoria => categoriaCache;

  /// Costo unitario del insumo.
  double? get costoUnitario => costoUnitarioCache;

  /// ID de la sucursal asignada.
  String? get sucursalId => sucursalIdCache;

  /// Indica si el stock cayó por debajo o igual al stock mínimo.
  bool get bajoMinimo => stockActual <= stockMinimo;

  /// Devuelve el stock formateado con su unidad de medida.
  String get stockFormateado {
    final cantStr = stockActual % 1 == 0
        ? stockActual.toInt().toString()
        : stockActual.toStringAsFixed(1);
    return '$cantStr $unidadMedida';
  }

  /// Devuelve el stock mínimo formateado con su unidad de medida.
  String get stockMinimoFormateado {
    final cantStr = stockMinimo % 1 == 0
        ? stockMinimo.toInt().toString()
        : stockMinimo.toStringAsFixed(1);
    return '$cantStr $unidadMedida';
  }

  factory ModeloInsumo.desdeJson(Map<String, dynamic> json) {
    final st = json['stock_actual'] ?? json['stock'];
    return ModeloInsumo(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Insumo',
      descripcion: json['descripcion'] as String?,
      stockActual: (st as num? ?? 0).toDouble(),
      stockMinimo: (json['stock_minimo'] as num? ?? 0).toDouble(),
      unidadMedida: json['unidad_medida'] as String? ?? 'unidad',
      sucursalId: json['sucursal_id'] as String?,
      categoria: json['categoria'] as String?,
      costoUnitario: (json['costo_unitario'] as num?)?.toDouble(),
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> aJson() {
    final mapa = <String, dynamic>{
      'barberia_id': barberiaId,
      'nombre': nombre,
      if (descripcion != null && descripcion!.isNotEmpty)
        'descripcion': descripcion,
      'stock': stockActual.toInt(),
      'stock_actual': stockActual.toInt(),
      'stock_minimo': stockMinimo.toInt(),
      'unidad_medida': unidadMedida,
      if (sucursalIdCache != null && sucursalIdCache!.isNotEmpty)
        'sucursal_id': sucursalIdCache,
      if (categoriaCache != null && categoriaCache!.isNotEmpty)
        'categoria': categoriaCache,
      if (costoUnitarioCache != null)
        'costo_unitario': costoUnitarioCache,
      'activo': activo,
    };

    if (id.trim().isNotEmpty) {
      mapa['id'] = id;
    }

    return mapa;
  }
}
