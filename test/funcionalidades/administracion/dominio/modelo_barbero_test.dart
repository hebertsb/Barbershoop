import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_barbero.dart';

void main() {
  group('ModeloBarbero', () {
    test('desdeJson y aJson hacen roundtrip completo con campos planos', () {
      final json = {
        'id': 'barbero-1',
        'perfil_id': 'perfil-1',
        'sucursal_id': 'sucursal-1',
        'barberia_id': 'barberia-1',
        'especialidades': ['corte', 'barba'],
        'activo': true,
        'nombre_perfil': 'Carlos Barbero',
        'url_foto_perfil': 'https://ejemplo.com/foto.png',
        'email_perfil': 'carlos@barberapp.com',
      };

      final barbero = ModeloBarbero.desdeJson(json);

      expect(barbero.id, 'barbero-1');
      expect(barbero.perfilId, 'perfil-1');
      expect(barbero.sucursalId, 'sucursal-1');
      expect(barbero.barberiaId, 'barberia-1');
      expect(barbero.especialidades, ['corte', 'barba']);
      expect(barbero.activo, true);
      expect(barbero.nombrePerfil, 'Carlos Barbero');
      expect(barbero.urlFotoPerfil, 'https://ejemplo.com/foto.png');
      expect(barbero.emailPerfil, 'carlos@barberapp.com');
      expect(barbero.aJson(), json);
    });

    test('desdeJson soporta join anidado de perfiles', () {
      final json = {
        'id': 'barbero-2',
        'perfil_id': 'perfil-2',
        'sucursal_id': 'sucursal-1',
        'barberia_id': 'barberia-1',
        'especialidades': [],
        'activo': true,
        'perfiles': {
          'nombre': 'Jorge Barbero',
          'url_foto': 'https://ejemplo.com/jorge.png',
          'email': 'jorge@barberapp.com',
        }
      };

      final barbero = ModeloBarbero.desdeJson(json);

      expect(barbero.id, 'barbero-2');
      expect(barbero.nombrePerfil, 'Jorge Barbero');
      expect(barbero.urlFotoPerfil, 'https://ejemplo.com/jorge.png');
      expect(barbero.emailPerfil, 'jorge@barberapp.com');
    });

    test('copyWith crea copia modificando atributos permitidos', () {
      final original = ModeloBarbero(
        id: 'barbero-3',
        perfilId: 'perfil-3',
        sucursalId: 'sucursal-1',
        barberiaId: 'barberia-1',
        especialidades: ['cejas'],
        activo: true,
      );

      final copia = original.copyWith(
        sucursalId: 'sucursal-2',
        especialidades: ['cejas', 'corte'],
        activo: false,
      );

      expect(copia.id, 'barbero-3');
      expect(copia.sucursalId, 'sucursal-2');
      expect(copia.especialidades, ['cejas', 'corte']);
      expect(copia.activo, false);
    });
  });
}
