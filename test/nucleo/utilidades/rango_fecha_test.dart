import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/utilidades/rango_fecha.dart';

void main() {
  group('rangoDeHoyEnUtc', () {
    test(
      'produce instantes UTC (con sufijo Z) que cubren todo el dia local',
      () {
        final ahora = DateTime(2026, 7, 17, 15, 30);
        final rango = rangoDeHoyEnUtc(ahora);

        expect(rango.inicio.isUtc, isTrue);
        expect(rango.fin.isUtc, isTrue);
        expect(rango.inicio.toIso8601String(), endsWith('Z'));
        expect(rango.fin.toIso8601String(), endsWith('Z'));
        expect(rango.fin.difference(rango.inicio), const Duration(days: 1));
      },
    );
  });
}
