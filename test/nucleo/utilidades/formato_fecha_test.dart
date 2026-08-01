import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/utilidades/formato_fecha.dart';

void main() {
  group('formatoHora', () {
    test('rellena con ceros hora y minuto de un digito', () {
      final fecha = DateTime(2026, 3, 5, 9, 5);
      expect(formatoHora(fecha), '09:05');
    });
  });

  group('formatoFechaCorta', () {
    test('rellena con ceros dia y mes de un digito', () {
      final fecha = DateTime(2026, 3, 5, 9, 5);
      expect(formatoFechaCorta(fecha), '05/03/2026');
    });
  });

  group('formatoFechaHora', () {
    test('combina fecha corta y hora con separador em-dash', () {
      final fecha = DateTime(2026, 3, 5, 9, 5);
      expect(formatoFechaHora(fecha), '05/03/2026 — 09:05');
    });
  });
}
