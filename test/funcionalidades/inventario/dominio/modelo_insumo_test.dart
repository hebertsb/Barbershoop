import 'package:barber_app/funcionalidades/inventario/dominio/modelo_insumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeloInsumo', () {
    final json = {
      'id': 'insumo-1',
      'barberia_id': 'barberia-1',
      'sucursal_id': 'sucursal-1',
      'nombre': 'Shampoo',
      'categoria': 'Cuidado capilar',
      'stock': 10,
      'stock_minimo': 3,
      'costo_unitario': 25.5,
    };

    test('desdeJson parsea todos los campos', () {
      final insumo = ModeloInsumo.desdeJson(json);
      expect(insumo.id, 'insumo-1');
      expect(insumo.barberiaId, 'barberia-1');
      expect(insumo.sucursalId, 'sucursal-1');
      expect(insumo.nombre, 'Shampoo');
      expect(insumo.categoria, 'Cuidado capilar');
      expect(insumo.stock, 10);
      expect(insumo.stockMinimo, 3);
      expect(insumo.costoUnitario, 25.5);
    });

    test('desdeJson soporta categoria y costo_unitario nulos', () {
      final sinOpcionales = Map<String, dynamic>.from(json)
        ..['categoria'] = null
        ..['costo_unitario'] = null;
      final insumo = ModeloInsumo.desdeJson(sinOpcionales);
      expect(insumo.categoria, isNull);
      expect(insumo.costoUnitario, isNull);
    });

    test('aJson hace el roundtrip', () {
      final insumo = ModeloInsumo.desdeJson(json);
      final devuelto = insumo.aJson();
      expect(devuelto['id'], 'insumo-1');
      expect(devuelto['nombre'], 'Shampoo');
      expect(devuelto['stock'], 10);
      expect(devuelto['stock_minimo'], 3);
    });

    test('bajoMinimo es true cuando stock <= stockMinimo', () {
      final bajo = ModeloInsumo.desdeJson(json).copyWith(stock: 3);
      final normal = ModeloInsumo.desdeJson(json).copyWith(stock: 5);
      expect(bajo.bajoMinimo, isTrue);
      expect(normal.bajoMinimo, isFalse);
    });

    test('copyWith reemplaza solo los campos indicados', () {
      final insumo = ModeloInsumo.desdeJson(json);
      final editado = insumo.copyWith(nombre: 'Acondicionador', stock: 20);
      expect(editado.id, insumo.id);
      expect(editado.nombre, 'Acondicionador');
      expect(editado.stock, 20);
      expect(editado.stockMinimo, insumo.stockMinimo);
    });
  });
}
