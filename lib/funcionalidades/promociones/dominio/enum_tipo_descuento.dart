enum TipoDescuento {
  porcentaje,
  montoFijo;

  String get etiqueta {
    switch (this) {
      case TipoDescuento.porcentaje:
        return 'Porcentaje (%)';
      case TipoDescuento.montoFijo:
        return 'Monto Fijo (Bs)';
    }
  }

  static TipoDescuento desdeTexto(String texto) {
    return TipoDescuento.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => TipoDescuento.porcentaje,
    );
  }
}
