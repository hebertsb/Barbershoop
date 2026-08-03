import 'package:intl/intl.dart';

String formatoMoneda(double monto) {
  final formatter = NumberFormat('#,##0.00', 'es_BO');
  final valorFormateado = formatter.format(monto);
  return 'Bs $valorFormateado';
}
