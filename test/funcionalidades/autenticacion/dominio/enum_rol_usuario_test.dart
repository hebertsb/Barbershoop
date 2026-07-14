import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';

void main() {
  group('RolUsuario', () {
    test('desdeTexto reconoce cada valor valido', () {
      expect(RolUsuario.desdeTexto('cliente'), RolUsuario.cliente);
      expect(RolUsuario.desdeTexto('barbero'), RolUsuario.barbero);
      expect(RolUsuario.desdeTexto('admin'), RolUsuario.admin);
      expect(RolUsuario.desdeTexto('superadmin'), RolUsuario.superadmin);
    });

    test('desdeTexto usa cliente como valor por defecto ante texto desconocido', () {
      expect(RolUsuario.desdeTexto('lo-que-sea'), RolUsuario.cliente);
    });
  });
}
