import 'package:barber_app/funcionalidades/promociones/dominio/enum_tipo_descuento.dart';
import 'package:barber_app/funcionalidades/promociones/dominio/modelo_promocion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeloPromocion', () {
    final json = {
      'id': 'promo-1',
      'barberia_id': 'barberia-1',
      'servicio_id': 'servicio-1',
      'titulo': 'Promo Verano',
      'descripcion': '20% de descuento en corte',
      'imagen': 'https://ejemplo.com/promo.jpg',
      'tipo_descuento': 'porcentaje',
      'descuento': 20.0,
      'fecha_inicio': '2026-07-01',
      'fecha_fin': '2026-07-31',
      'activo': true,
      'servicios': {'nombre': 'Corte Clásico'},
    };

    test('desdeJson parsea todos los campos correctamente', () {
      final promo = ModeloPromocion.desdeJson(json);
      expect(promo.id, 'promo-1');
      expect(promo.barberiaId, 'barberia-1');
      expect(promo.servicioId, 'servicio-1');
      expect(promo.nombreServicio, 'Corte Clásico');
      expect(promo.titulo, 'Promo Verano');
      expect(promo.descripcion, '20% de descuento en corte');
      expect(promo.imagen, 'https://ejemplo.com/promo.jpg');
      expect(promo.tipoDescuento, TipoDescuento.porcentaje);
      expect(promo.descuento, 20.0);
      expect(promo.fechaInicio, DateTime(2026, 7, 1));
      expect(promo.fechaFin, DateTime(2026, 7, 31));
      expect(promo.activo, isTrue);
    });

    test('calcularDescuento calcula porcentaje correctamente', () {
      final promo = ModeloPromocion.desdeJson(json);
      expect(promo.calcularDescuento(100.0), 20.0);
      expect(promo.calcularPrecioFinal(100.0), 80.0);
    });

    test('calcularDescuento calcula monto fijo correctamente', () {
      final jsonFijo = Map<String, dynamic>.from(json)
        ..['tipo_descuento'] = 'monto_fijo'
        ..['descuento'] = 15.0;
      final promo = ModeloPromocion.desdeJson(jsonFijo);
      expect(promo.calcularDescuento(100.0), 15.0);
      expect(promo.calcularPrecioFinal(100.0), 85.0);
    });

    test('calcularDescuento no excede el precio original', () {
      final jsonExcesivo = Map<String, dynamic>.from(json)
        ..['tipo_descuento'] = 'monto_fijo'
        ..['descuento'] = 150.0;
      final promo = ModeloPromocion.desdeJson(jsonExcesivo);
      expect(promo.calcularDescuento(100.0), 100.0);
      expect(promo.calcularPrecioFinal(100.0), 0.0);
    });

    test('estaVigente evalua el rango de fechas e activo', () {
      final hoy = DateTime.now();
      final vigente = ModeloPromocion.desdeJson(json).copyWith(
        fechaInicio: hoy.subtract(const Duration(days: 1)),
        fechaFin: hoy.add(const Duration(days: 1)),
        activo: true,
      );
      final vencida = vigente.copyWith(
        fechaFin: hoy.subtract(const Duration(days: 1)),
      );
      final inactiva = vigente.copyWith(activo: false);

      expect(vigente.estaVigente, isTrue);
      expect(vencida.estaVigente, isFalse);
      expect(inactiva.estaVigente, isFalse);
    });

    test('desdeJson parsea limite_usos_por_cliente cuando está presente', () {
      final jsonConLimite = Map<String, dynamic>.from(json)
        ..['limite_usos_por_cliente'] = 2;
      final promo = ModeloPromocion.desdeJson(jsonConLimite);
      expect(promo.limiteUsosPorCliente, 2);
    });

    test('desdeJson deja limiteUsosPorCliente en null si falta la clave', () {
      final promo = ModeloPromocion.desdeJson(json);
      expect(promo.limiteUsosPorCliente, isNull);
    });

    test('desdeJson deja limiteUsosPorCliente en null si la clave es null', () {
      final jsonNulo = Map<String, dynamic>.from(json)
        ..['limite_usos_por_cliente'] = null;
      final promo = ModeloPromocion.desdeJson(jsonNulo);
      expect(promo.limiteUsosPorCliente, isNull);
    });

    test('aJson incluye limite_usos_por_cliente siempre, incluso en null', () {
      final promoSinLimite = ModeloPromocion.desdeJson(json);
      expect(promoSinLimite.limiteUsosPorCliente, isNull);
      expect(
        promoSinLimite.aJson().containsKey('limite_usos_por_cliente'),
        isTrue,
      );
      expect(promoSinLimite.aJson()['limite_usos_por_cliente'], isNull);

      final jsonConLimite = Map<String, dynamic>.from(json)
        ..['limite_usos_por_cliente'] = 3;
      final promoConLimite = ModeloPromocion.desdeJson(jsonConLimite);
      expect(
        promoConLimite.aJson().containsKey('limite_usos_por_cliente'),
        isTrue,
      );
      expect(promoConLimite.aJson()['limite_usos_por_cliente'], 3);
    });

    test('desdeJson parsea capacidad_maxima cuando está presente', () {
      final jsonConCapacidad = Map<String, dynamic>.from(json)
        ..['capacidad_maxima'] = 50;
      final promo = ModeloPromocion.desdeJson(jsonConCapacidad);
      expect(promo.capacidadMaxima, 50);
    });

    test('desdeJson deja capacidadMaxima en null si falta la clave', () {
      final promo = ModeloPromocion.desdeJson(json);
      expect(promo.capacidadMaxima, isNull);
    });

    test('desdeJson deja capacidadMaxima en null si la clave es null', () {
      final jsonNulo = Map<String, dynamic>.from(json)
        ..['capacidad_maxima'] = null;
      final promo = ModeloPromocion.desdeJson(jsonNulo);
      expect(promo.capacidadMaxima, isNull);
    });

    test('aJson incluye capacidad_maxima siempre, incluso en null', () {
      final promoSinCapacidad = ModeloPromocion.desdeJson(json);
      expect(promoSinCapacidad.capacidadMaxima, isNull);
      expect(
        promoSinCapacidad.aJson().containsKey('capacidad_maxima'),
        isTrue,
      );
      expect(promoSinCapacidad.aJson()['capacidad_maxima'], isNull);

      final jsonConCapacidad = Map<String, dynamic>.from(json)
        ..['capacidad_maxima'] = 50;
      final promoConCapacidad = ModeloPromocion.desdeJson(jsonConCapacidad);
      expect(
        promoConCapacidad.aJson().containsKey('capacidad_maxima'),
        isTrue,
      );
      expect(promoConCapacidad.aJson()['capacidad_maxima'], 50);
    });
  });
}
