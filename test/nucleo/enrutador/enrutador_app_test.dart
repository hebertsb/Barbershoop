import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import 'package:barber_app/nucleo/enrutador/enrutador_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const perfilSinBarberia = ModeloPerfil(
    id: 'usuario-1',
    email: 'usuario@ejemplo.com',
    barberiaId: null,
    rol: RolUsuario.cliente,
    nombre: 'Usuario Prueba',
    urlFoto: null,
    telefono: null,
  );

  const perfilConBarberia = ModeloPerfil(
    id: 'usuario-2',
    email: 'usuario2@ejemplo.com',
    barberiaId: 'barberia-1',
    rol: RolUsuario.admin,
    nombre: 'Admin Prueba',
    urlFoto: null,
    telefono: null,
  );

  group('calcularRedireccion', () {
    test('sin sesión, en /login → null (se queda)', () {
      final resultado = calcularRedireccion(
        haySesion: false,
        estadoPerfil: const AsyncValue.loading(),
        ubicacionActual: '/login',
      );
      expect(resultado, isNull);
    });

    test('sin sesión, en / → /login', () {
      final resultado = calcularRedireccion(
        haySesion: false,
        estadoPerfil: const AsyncValue.loading(),
        ubicacionActual: '/',
      );
      expect(resultado, '/login');
    });

    test('sin sesión, en /seleccion-barberia → /login', () {
      final resultado = calcularRedireccion(
        haySesion: false,
        estadoPerfil: const AsyncValue.loading(),
        ubicacionActual: '/seleccion-barberia',
      );
      expect(resultado, '/login');
    });

    test('con sesión, perfil cargando → null', () {
      final resultado = calcularRedireccion(
        haySesion: true,
        estadoPerfil: const AsyncValue.loading(),
        ubicacionActual: '/',
      );
      expect(resultado, isNull);
    });

    test(
      'con sesión, perfil con error → null (no redirige a /login) '
      '— regresión del bug crítico',
      () {
        final resultado = calcularRedireccion(
          haySesion: true,
          estadoPerfil: AsyncValue<ModeloPerfil?>.error(
            Exception('error de prueba'),
            StackTrace.empty,
          ),
          ubicacionActual: '/seleccion-barberia',
        );
        expect(resultado, isNull);
      },
    );

    test('con sesión, perfil resuelto en null, en / → /login', () {
      final resultado = calcularRedireccion(
        haySesion: true,
        estadoPerfil: const AsyncValue.data(null),
        ubicacionActual: '/',
      );
      expect(resultado, '/login');
    });

    test(
      'con sesión, perfil sin barberiaId, en /seleccion-barberia → null (se queda)',
      () {
        final resultado = calcularRedireccion(
          haySesion: true,
          estadoPerfil: const AsyncValue.data(perfilSinBarberia),
          ubicacionActual: '/seleccion-barberia',
        );
        expect(resultado, isNull);
      },
    );

    test('con sesión, perfil sin barberiaId, en / → /seleccion-barberia', () {
      final resultado = calcularRedireccion(
        haySesion: true,
        estadoPerfil: const AsyncValue.data(perfilSinBarberia),
        ubicacionActual: '/',
      );
      expect(resultado, '/seleccion-barberia');
    });

    test('con sesión, perfil con barberiaId, en /login → /', () {
      final resultado = calcularRedireccion(
        haySesion: true,
        estadoPerfil: const AsyncValue.data(perfilConBarberia),
        ubicacionActual: '/login',
      );
      expect(resultado, '/');
    });

    test('con sesión, perfil con barberiaId, en /seleccion-barberia → /', () {
      final resultado = calcularRedireccion(
        haySesion: true,
        estadoPerfil: const AsyncValue.data(perfilConBarberia),
        ubicacionActual: '/seleccion-barberia',
      );
      expect(resultado, '/');
    });

    test(
      'con sesión, perfil con barberiaId, en cualquier otra ruta (ej. /) → null (se queda)',
      () {
        final resultado = calcularRedireccion(
          haySesion: true,
          estadoPerfil: const AsyncValue.data(perfilConBarberia),
          ubicacionActual: '/',
        );
        expect(resultado, isNull);
      },
    );
  });
}
