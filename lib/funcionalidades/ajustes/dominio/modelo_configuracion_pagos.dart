import 'enum_modo_pago.dart';
class ModeloConfiguracionPagos {
  const ModeloConfiguracionPagos({
    this.modo = ModoPago.opcional,
    this.porcentajeSena = 30,
    this.minutosGraciaPago = 30,
    this.urlQrBanco,
  });

  final ModoPago modo;
  final int porcentajeSena;
  final int minutosGraciaPago;
  final String? urlQrBanco;

  static const claveModoPago = 'modo_pago';
  static const clavePorcentajeSena = 'porcentaje_sena';
  static const claveMinutosGraciaPago = 'minutos_gracia_pago';
  static const claveUrlQrBanco = 'url_qr_banco';

  /// Todas las claves de `configuraciones_barberia` que componen este modelo.
  static const claves = [
    claveModoPago,
    clavePorcentajeSena,
    claveMinutosGraciaPago,
    claveUrlQrBanco,
  ];

  factory ModeloConfiguracionPagos.desdeJson(Map<String, dynamic> json) {
    const defecto = ModeloConfiguracionPagos();
    var modo = defecto.modo;
    var porcentajeSena = defecto.porcentajeSena;
    var minutosGraciaPago = defecto.minutosGraciaPago;
    String? urlQrBanco;

    final valorModoPago = json[claveModoPago];
    if (valorModoPago is Map<String, dynamic>) {
      final texto = valorModoPago['modo'];
      if (texto is String) modo = ModoPago.desdeTexto(texto);
    }

    final valorPorcentajeSena = json[clavePorcentajeSena];
    if (valorPorcentajeSena is Map<String, dynamic>) {
      final numero = valorPorcentajeSena['porcentaje'];
      if (numero is num) porcentajeSena = numero.toInt();
    }

    final valorMinutosGraciaPago = json[claveMinutosGraciaPago];
    if (valorMinutosGraciaPago is Map<String, dynamic>) {
      final numero = valorMinutosGraciaPago['minutos'];
      if (numero is num) minutosGraciaPago = numero.toInt();
    }

    final valorUrlQrBanco = json[claveUrlQrBanco];
    if (valorUrlQrBanco is Map<String, dynamic>) {
      final texto = valorUrlQrBanco['url'];
      if (texto is String) urlQrBanco = texto;
    }

    return ModeloConfiguracionPagos(
      modo: modo,
      porcentajeSena: porcentajeSena,
      minutosGraciaPago: minutosGraciaPago,
      urlQrBanco: urlQrBanco,
    );
  }

  /// Mapa `{clave: valor}` listo para volcarse fila por fila en
  /// `configuraciones_barberia`. Incluye siempre las 4 claves, incluso
  /// cuando [urlQrBanco] es `null`, para que un borrado se persista.
  Map<String, dynamic> aJson() {
    return {
      claveModoPago: {'modo': modo.aTexto()},
      clavePorcentajeSena: {'porcentaje': porcentajeSena},
      claveMinutosGraciaPago: {'minutos': minutosGraciaPago},
      claveUrlQrBanco: {'url': urlQrBanco},
    };
  }

  /// Monto que corresponde pagar por QR para un servicio de precio
  /// [precioServicio]: el precio completo si el modo no es seña, o el
  /// porcentaje de seña configurado si lo es.
  ///
  /// Devuelve `null` cuando no se puede calcular un monto válido (precio
  /// todavía no disponible, ej. servicio sin cargar, o `<= 0`) — quien llama
  /// debe evitar ofrecer un pago con ese resultado (nunca navegar a la
  /// pantalla de pago ni habilitar su botón con un monto de $0).
  double? calcularMontoAPagar(double? precioServicio) {
    if (precioServicio == null || precioServicio <= 0) return null;
    final monto = modo == ModoPago.sena
        ? precioServicio * porcentajeSena / 100
        : precioServicio;
    return monto <= 0 ? null : monto;
  }

  ModeloConfiguracionPagos copyWith({
    ModoPago? modo,
    int? porcentajeSena,
    int? minutosGraciaPago,
    String? urlQrBanco,
    bool limpiarUrlQrBanco = false,
  }) {
    return ModeloConfiguracionPagos(
      modo: modo ?? this.modo,
      porcentajeSena: porcentajeSena ?? this.porcentajeSena,
      minutosGraciaPago: minutosGraciaPago ?? this.minutosGraciaPago,
      urlQrBanco: limpiarUrlQrBanco ? null : (urlQrBanco ?? this.urlQrBanco),
    );
  }
}