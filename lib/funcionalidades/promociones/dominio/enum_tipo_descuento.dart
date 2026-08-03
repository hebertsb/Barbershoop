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
    final t = texto.toLowerCase().trim();
    if (t.contains('monto') || t.contains('fijo') || t == 'montofijo') {
      return TipoDescuento.montoFijo;
    }
    return TipoDescuento.porcentaje;
  }
}
