import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_resumen_ingresos_barbero.dart';

void main() {
  group('ModeloResumenIngresosBarbero', () {
    test('desdeJson mapea valores reales', () {
      final json = {
        'ingresos_hoy': 120.0,
        'ingresos_semana': 540.0,
        'ingresos_mes': 2100.0,
        'citas_hoy': 4,
      };

      final resumen = ModeloResumenIngresosBarbero.desdeJson(json);

      expect(resumen.ingresosHoy, 120.0);
      expect(resumen.ingresosSemana, 540.0);
      expect(resumen.ingresosMes, 2100.0);
      expect(resumen.citasHoy, 4);
    });
  });
}
