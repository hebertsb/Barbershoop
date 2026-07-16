import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_autenticacion.dart';
import '../../dominio/modelo_barberia_resumen.dart';
import '../../dominio/modelo_perfil.dart';

final repositorioAutenticacionProvider = Provider<RepositorioAutenticacion>((ref) {
  return RepositorioAutenticacionSupabase();
});

class ControladorAutenticacion extends AsyncNotifier<ModeloPerfil?> {
  @override
  Future<ModeloPerfil?> build() async {
    return ref.read(repositorioAutenticacionProvider).obtenerPerfilActual();
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

  Future<void> asignarBarberia(String barberiaId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositorio = ref.read(repositorioAutenticacionProvider);
      await repositorio.asignarBarberia(barberiaId);
      return repositorio.obtenerPerfilActual();
    });
  }

  Future<void> cerrarSesion() async {
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
