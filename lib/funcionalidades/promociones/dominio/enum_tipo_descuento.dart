enum TipoDescuento {
  porcentaje,
  montoFijo;

  static TipoDescuento desdeTexto(String texto) {
    switch (texto) {
      case 'porcentaje':
        return TipoDescuento.porcentaje;
      case 'monto_fijo':
        return TipoDescuento.montoFijo;
      default:
        return TipoDescuento.porcentaje;
    }
  }

  String aTexto() {
    switch (this) {
      case TipoDescuento.porcentaje:
        return 'porcentaje';
      case TipoDescuento.montoFijo:
        return 'monto_fijo';
    }
  }
}
