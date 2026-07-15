import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/datos/repositorio_autenticacion.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import 'package:barber_app/nucleo/errores/excepciones_app.dart';

class RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  ModeloPerfil? perfilActual;
  Object? errorAlIniciarSesion;
  bool cancelarGoogle = false;

  @override
  Future<void> iniciarSesionConGoogle() async {
    if (errorAlIniciarSesion != null) throw errorAlIniciarSesion!;
    if (cancelarGoogle) return;
    perfilActual = const ModeloPerfil(
      id: 'uid-1',
      email: 'ana@example.com',
      barberiaId: null,
      rol: RolUsuario.cliente,
      nombre: 'Ana',
      urlFoto: null,
      telefono: null,
    );
  }

  @override
  Future<void> iniciarSesionConFacebook() => iniciarSesionConGoogle();

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async => perfilActual;

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async => [];

  @override
  Future<void> asignarBarberia(String barberiaId) async {
    perfilActual = perfilActual?.copyWith(barberiaId: barberiaId);
  }

  @override
  Future<void> cerrarSesion() async {
    perfilActual = null;
  }
}

void main() {
  test('build() sin sesion previa devuelve null', () async {
    final falso = RepositorioAutenticacionFalso();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    final perfil = await contenedor.read(controladorAutenticacionProvider.future);
    expect(perfil, isNull);
  });

  test('iniciarSesionConGoogle exitoso deja el perfil en el estado', () async {
    final falso = RepositorioAutenticacionFalso();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.value?.email, 'ana@example.com');
  });

  test('iniciarSesionConGoogle cancelado no deja error ni perfil', () async {
    final falso = RepositorioAutenticacionFalso()..cancelarGoogle = true;
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.hasError, isFalse);
    expect(estado.value, isNull);
  });

  test('error de red al iniciar sesion queda expuesto como ExcepcionRed', () async {
    final falso = RepositorioAutenticacionFalso()..errorAlIniciarSesion = const ExcepcionRed();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.hasError, isTrue);
    expect(estado.error, isA<ExcepcionRed>());
  });

  test('asignarBarberia actualiza barberiaId en el perfil', () async {
    final falso = RepositorioAutenticacionFalso();
    final contenedor = ProviderContainer(overrides: [
      repositorioAutenticacionProvider.overrideWithValue(falso),
    ]);
    addTearDown(contenedor.dispose);

    await contenedor.read(controladorAutenticacionProvider.future);
    await contenedor.read(controladorAutenticacionProvider.notifier).iniciarSesionConGoogle();
    await contenedor.read(controladorAutenticacionProvider.notifier).asignarBarberia('barberia-1');

    final estado = contenedor.read(controladorAutenticacionProvider);
    expect(estado.value?.barberiaId, 'barberia-1');
  });
}
