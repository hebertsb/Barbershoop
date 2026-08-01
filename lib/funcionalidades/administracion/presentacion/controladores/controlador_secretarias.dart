import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_secretaria.dart';

class ControladorSecretarias extends AsyncNotifier<List<ModeloSecretaria>> {
  @override
  FutureOr<List<ModeloSecretaria>> build() async {
    return ref.read(repositorioAdministracionProvider).obtenerSecretarias();
  }

  Future<void> invitarSecretaria({
    required String email,
    required String sucursalId,
  }) async {
    state = const AsyncLoading<List<ModeloSecretaria>>();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(repositorioAdministracionProvider);
      await repo.invitarSecretaria(email: email, sucursalId: sucursalId);
      return repo.obtenerSecretarias();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> revocarSecretaria(String perfilId) async {
    state = const AsyncLoading<List<ModeloSecretaria>>();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(repositorioAdministracionProvider);
      await repo.revocarSecretaria(perfilId);
      return repo.obtenerSecretarias();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorSecretariasProvider =
    AsyncNotifierProvider<ControladorSecretarias, List<ModeloSecretaria>>(() {
      return ControladorSecretarias();
    });
