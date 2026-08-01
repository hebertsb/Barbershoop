import 'package:barber_app/funcionalidades/promociones/dominio/modelo_uso_promocion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeloUsoPromocion', () {
    test('desdeJson parsea todos los campos', () {
      final json = {
        'cliente_id': 'cliente-1',
        'cliente_nombre': 'Juan Pérez',
        'veces_usada': 3,
      };
      final uso = ModeloUsoPromocion.desdeJson(json);
      expect(uso.clienteId, 'cliente-1');
      expect(uso.clienteNombre, 'Juan Pérez');
      expect(uso.vecesUsada, 3);
    });
  });
}
