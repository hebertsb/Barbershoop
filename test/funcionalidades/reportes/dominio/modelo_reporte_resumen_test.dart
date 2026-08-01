import 'package:barber_app/funcionalidades/reportes/dominio/modelo_reporte_resumen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeloReporteResumen', () {
    test('desdeJson parsea los datos correctamente', () {
      final json = {
        'total_ingresos': 1500.5,
        'total_descuentos': 200.0,
        'citas_completadas': 30,
        'citas_canceladas': 3,
        'ticket_promedio': 50.02,
      };

      final modelo = ModeloReporteResumen.desdeJson(json);
      expect(modelo.totalIngresos, 1500.5);
      expect(modelo.totalDescuentos, 200.0);
      expect(modelo.citasCompletadas, 30);
      expect(modelo.citasCanceladas, 3);
      expect(modelo.ticketPromedio, 50.02);
    });
  });
}
