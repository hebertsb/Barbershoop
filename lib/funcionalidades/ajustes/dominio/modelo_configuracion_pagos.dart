import 'enum_modo_pago.dart';

class ModeloConfiguracionPagos {
  const ModeloConfiguracionPagos({
    required this.modo,
    required this.porcentajeSena,
    required this.minutosGraciaPago,
    this.urlQrBanco,
  });

  final ModoPago modo;
  final int porcentajeSena;
  final int minutosGraciaPago;
  final String? urlQrBanco;

  /// Claves de `configuraciones_barberia` que componen esta configuración
  /// -- usadas por el repositorio para filtrar el `select`.
  static const claves = [
    'modo_pago',
    'porcentaje_sena',
    'minutos_gracia_pago',
    'url_qr_banco',
  ];

  /// Monto que corresponde pagar por [precioTotal] según el modo vigente:
  /// obligatorio/opcional pagan el total, seña paga el porcentaje
  /// configurado. `null` si no hay precio (cita sin precio calculado
  /// todavía).
  double? calcularMontoAPagar(double? precioTotal) {
    if (precioTotal == null) return null;
    if (modo == ModoPago.sena) {
      return precioTotal * (porcentajeSena / 100);
    }
    return precioTotal;
  }

  factory ModeloConfiguracionPagos.desdeJson(Map<String, dynamic> json) {
    int? extraerNumero(String clave) {
      final valor = json[clave];
      if (valor is Map<String, dynamic>) {
        final n = valor['valor'] ?? valor.values.firstOrNull;
        if (n is num) return n.toInt();
      }
      return null;
    }

    String? extraerTexto(String clave) {
      final valor = json[clave];
      if (valor is Map<String, dynamic>) {
        final t = valor['url'] ?? valor.values.firstOrNull;
        if (t is String) return t;
      }
      return null;
    }

    final modoValor = json['modo_pago'];
    final modoTexto = modoValor is Map<String, dynamic>
        ? modoValor['modo'] as String?
        : null;

    return ModeloConfiguracionPagos(
      modo: ModoPago.desdeTexto(modoTexto ?? 'opcional'),
      porcentajeSena: extraerNumero('porcentaje_sena') ?? 50,
      minutosGraciaPago: extraerNumero('minutos_gracia_pago') ?? 30,
      urlQrBanco: extraerTexto('url_qr_banco'),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'modo_pago': {'modo': modo.aTexto()},
      'porcentaje_sena': {'valor': porcentajeSena},
      'minutos_gracia_pago': {'valor': minutosGraciaPago},
      'url_qr_banco': {'url': urlQrBanco},
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
