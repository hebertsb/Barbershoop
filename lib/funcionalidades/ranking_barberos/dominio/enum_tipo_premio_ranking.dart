enum TipoPremioRanking {
  dinero,
  diaLibre,
  kitProductos,
  descuentoServicio;

  String get aTexto => name;

  /// Etiqueta legible en español para mostrar en la UI.
  String get etiqueta {
    switch (this) {
      case TipoPremioRanking.dinero:
        return 'Premio en dinero';
      case TipoPremioRanking.diaLibre:
        return 'Día libre';
      case TipoPremioRanking.kitProductos:
        return 'Kit de productos';
      case TipoPremioRanking.descuentoServicio:
        return 'Descuento en servicio';
    }
  }

  static TipoPremioRanking desdeTexto(String texto) {
    return TipoPremioRanking.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => TipoPremioRanking.dinero,
    );
  }
}
