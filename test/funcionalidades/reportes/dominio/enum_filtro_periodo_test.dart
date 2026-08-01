import 'package:barber_app/funcionalidades/reportes/dominio/enum_filtro_periodo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FiltroPeriodo', () {
    test('etiqueta devuelve nombres legibles', () {
      expect(FiltroPeriodo.hoy.etiqueta, 'Hoy');
      expect(FiltroPeriodo.estaSemana.etiqueta, 'Esta semana');
      expect(FiltroPeriodo.esteMes.etiqueta, 'Este mes');
      expect(FiltroPeriodo.esteAnio.etiqueta, 'Este año');
      expect(FiltroPeriodo.personalizado.etiqueta, 'Personalizado');
    });

    test('obtenerRangoFechas calcula rango adecuado para hoy', () {
      final ahora = DateTime.now();
      final (inicio, fin) = FiltroPeriodo.hoy.obtenerRangoFechas();
      expect(inicio.year, ahora.year);
      expect(inicio.month, ahora.month);
      expect(inicio.day, ahora.day);
      expect(fin.hour, 23);
      expect(fin.minute, 59);
    });
  });
}
