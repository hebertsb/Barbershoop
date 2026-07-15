import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import 'package:barber_app/nucleo/errores/excepciones_app.dart';

class _RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  bool googleLlamado = false;

  @override
  Future<void> iniciarSesionConGoogle() async {
    googleLlamado = true;
  }

  @override
  Future<void> iniciarSesionConFacebook() async {}

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async => null;

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async => [];

  @override
  Future<void> asignarBarberia(String barberiaId) async {}

  @override
  Future<void> cerrarSesion() async {}
}

class _RepositorioAutenticacionConErrorDeRed implements RepositorioAutenticacion {
  @override
  Future<void> iniciarSesionConGoogle() async {
    throw const ExcepcionRed();
  }

  @override
  Future<void> iniciarSesionConFacebook() async {}

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async => null;

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async => [];

  @override
  Future<void> asignarBarberia(String barberiaId) async {}

  @override
  Future<void> cerrarSesion() async {}
}

void main() {
  testWidgets('muestra los dos botones y dispara login de Google al tocar', (tester) async {
    final falso = _RepositorioAutenticacionFalso();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioAutenticacionProvider.overrideWithValue(falso)],
        child: const MaterialApp(home: PantallaInicioSesion()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Continuar con Facebook'), findsOneWidget);

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(falso.googleLlamado, isTrue);
  });

  testWidgets('muestra un SnackBar con el mensaje de error de red al fallar el login de Google', (
    tester,
  ) async {
    final falso = _RepositorioAutenticacionConErrorDeRed();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioAutenticacionProvider.overrideWithValue(falso)],
        child: const MaterialApp(home: PantallaInicioSesion()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error de conexión. Verifica tu internet.'), findsOneWidget);
  });
}
