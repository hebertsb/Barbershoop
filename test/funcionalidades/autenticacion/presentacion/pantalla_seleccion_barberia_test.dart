import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart';
import 'package:barber_app/nucleo/errores/excepciones_app.dart';

class _RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  _RepositorioAutenticacionFalso({this.barberias = const [], this.errorAlAsignar})
      : perfilActual = const ModeloPerfil(
          id: 'uid-1',
          email: 'ana@example.com',
          barberiaId: null,
          rol: RolUsuario.cliente,
          nombre: 'Ana',
          urlFoto: null,
          telefono: null,
        );

  final List<ModeloBarberiaResumen> barberias;
  final Object? errorAlAsignar;
  ModeloPerfil? perfilActual;
  String? barberiaIdRecibido;

  @override
  Future<void> iniciarSesionConGoogle() async {}

  @override
  Future<void> iniciarSesionConFacebook() async {}

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async => perfilActual;

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async => barberias;

  @override
  Future<void> asignarBarberia(String barberiaId) async {
    barberiaIdRecibido = barberiaId;
    if (errorAlAsignar != null) throw errorAlAsignar!;
    perfilActual = perfilActual?.copyWith(barberiaId: barberiaId);
  }

  @override
  Future<void> cerrarSesion() async {
    perfilActual = null;
  }
}

void main() {
  testWidgets('muestra el mensaje de lista vacía cuando no hay barberías activas', (tester) async {
    final falso = _RepositorioAutenticacionFalso(barberias: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioAutenticacionProvider.overrideWithValue(falso)],
        child: const MaterialApp(home: PantallaSeleccionBarberia()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay barberías disponibles todavía.'), findsOneWidget);
  });

  testWidgets('muestra la lista de barberías y llama asignarBarberia al tocar una', (tester) async {
    final falso = _RepositorioAutenticacionFalso(
      barberias: const [ModeloBarberiaResumen(id: 'b1', nombre: 'Barbería Test')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioAutenticacionProvider.overrideWithValue(falso)],
        child: const MaterialApp(home: PantallaSeleccionBarberia()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Barbería Test'), findsOneWidget);

    await tester.tap(find.text('Barbería Test'));
    await tester.pumpAndSettle();

    expect(falso.barberiaIdRecibido, 'b1');
  });

  testWidgets('muestra un SnackBar con el mensaje de error al fallar asignarBarberia', (
    tester,
  ) async {
    final falso = _RepositorioAutenticacionFalso(
      barberias: const [ModeloBarberiaResumen(id: 'b1', nombre: 'Barbería Test')],
      errorAlAsignar: const ExcepcionRed(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioAutenticacionProvider.overrideWithValue(falso)],
        child: const MaterialApp(home: PantallaSeleccionBarberia()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Barbería Test'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error de conexión. Verifica tu internet.'), findsOneWidget);
  });
}
