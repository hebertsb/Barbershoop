import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_autenticacion.dart';
import '../../dominio/enum_rol_usuario.dart';
import '../../dominio/modelo_barberia_resumen.dart';
import '../../dominio/modelo_perfil.dart';

final repositorioAutenticacionProvider = Provider<RepositorioAutenticacion>((ref) {
  return RepositorioAutenticacionSupabase();
});

class ControladorAutenticacion extends AsyncNotifier<ModeloPerfil?> {
  ModeloPerfil? _perfilPersonalizado;

  @override
  Future<ModeloPerfil?> build() async {
    if (_perfilPersonalizado != null) return _perfilPersonalizado;

    final cliente = ref.read(repositorioAutenticacionProvider);
    final perfil = await cliente.obtenerPerfilActual();
    return perfil;
  }

  Future<void> iniciarSesionConGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.iniciarSesionConGoogle();
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> iniciarSesionConFacebook() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.iniciarSesionConFacebook();
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> iniciarSesionConEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.iniciarSesionConEmail(email, password);
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> ingresarComoRol(RolUsuario rol) async {
    state = const AsyncLoading();
    _perfilPersonalizado = ModeloPerfil(
      id: 'demo-${rol.name}-id',
      email: '${rol.name}@barberapp.com',
      barberiaId: 'barberia-demo-1',
      rol: rol,
      nombre: 'Usuario ${rol.name.toUpperCase()}',
      urlFoto: null,
      telefono: null,
    );
    state = AsyncData(_perfilPersonalizado);
  }

  Future<void> asignarBarberia(String barberiaId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (_perfilPersonalizado != null) {
        _perfilPersonalizado = _perfilPersonalizado!.copyWith(barberiaId: barberiaId);
        return _perfilPersonalizado;
      }
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.asignarBarberia(barberiaId);
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> cerrarSesion() async {
    _perfilPersonalizado = null;
    await ref.read(repositorioAutenticacionProvider).cerrarSesion();
    state = const AsyncData(null);
  }
}

final controladorAutenticacionProvider =
    AsyncNotifierProvider<ControladorAutenticacion, ModeloPerfil?>(
  ControladorAutenticacion.new,
);

final barberiasActivasProvider = FutureProvider.autoDispose<List<ModeloBarberiaResumen>>((ref) {
  return ref.read(repositorioAutenticacionProvider).obtenerBarberiasActivas();
});
