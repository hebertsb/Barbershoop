import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';

void main() {
  test('desdeJson y aJson hacen roundtrip completo', () {
    final json = {
      'id': 'uid-1',
      'email': 'ana@example.com',
      'barberia_id': 'barberia-1',
      'rol': 'admin',
      'nombre': 'Ana',
      'url_foto': 'https://ejemplo.com/foto.png',
      'telefono': '70000000',
    };

    final perfil = ModeloPerfil.desdeJson(json);

    expect(perfil.id, 'uid-1');
    expect(perfil.email, 'ana@example.com');
    expect(perfil.barberiaId, 'barberia-1');
    expect(perfil.rol, RolUsuario.admin);
    expect(perfil.nombre, 'Ana');
    expect(perfil.urlFoto, 'https://ejemplo.com/foto.png');
    expect(perfil.telefono, '70000000');
    expect(perfil.aJson(), json);
  });

  test('desdeJson admite barberia_id nulo (perfil recien creado)', () {
    final perfil = ModeloPerfil.desdeJson({
      'id': 'uid-2',
      'email': 'nuevo@example.com',
      'barberia_id': null,
      'rol': 'cliente',
      'nombre': null,
      'url_foto': null,
      'telefono': null,
    });

    expect(perfil.barberiaId, isNull);
    expect(perfil.rol, RolUsuario.cliente);
  });

  test('copyWith actualiza barberiaId sin tocar el resto', () {
    final original = ModeloPerfil.desdeJson({
      'id': 'uid-3',
      'email': 'x@example.com',
      'barberia_id': null,
      'rol': 'cliente',
      'nombre': 'X',
      'url_foto': null,
      'telefono': null,
    });

    final actualizado = original.copyWith(barberiaId: 'barberia-9');

    expect(actualizado.barberiaId, 'barberia-9');
    expect(actualizado.id, original.id);
    expect(actualizado.nombre, original.nombre);
  });

  test('desdeJson admite email nulo (Facebook sin permiso de correo)', () {
    final perfil = ModeloPerfil.desdeJson({
      'id': 'uid-4',
      'email': null,
      'barberia_id': null,
      'rol': 'cliente',
      'nombre': 'Sin Correo',
      'url_foto': null,
      'telefono': null,
    });

    expect(perfil.email, isNull);
    expect(perfil.id, 'uid-4');
  });
}
