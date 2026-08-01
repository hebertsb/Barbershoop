import 'package:barber_app/funcionalidades/resenas/dominio/modelo_resena.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeloResena', () {
    test('desdeJson parsea todos los campos', () {
      final json = {
        'id': 'resena-1',
        'cliente_nombre': 'Juan Pérez',
        'calificacion': 5,
        'comentario': 'Excelente corte',
        'creado_en': '2026-07-20T10:00:00Z',
      };
      final resena = ModeloResena.desdeJson(json);
      expect(resena.id, 'resena-1');
      expect(resena.clienteNombre, 'Juan Pérez');
      expect(resena.calificacion, 5);
      expect(resena.comentario, 'Excelente corte');
      expect(resena.creadoEn, DateTime.parse('2026-07-20T10:00:00Z'));
    });

    test('desdeJson soporta comentario nulo', () {
      final json = {
        'id': 'resena-2',
        'cliente_nombre': 'Ana Gómez',
        'calificacion': 4,
        'comentario': null,
        'creado_en': '2026-07-20T10:00:00Z',
      };
      final resena = ModeloResena.desdeJson(json);
      expect(resena.comentario, isNull);
    });
  });
}
