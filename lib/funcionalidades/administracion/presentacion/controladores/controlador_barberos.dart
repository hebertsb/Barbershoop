import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_barbero.dart';

class ControladorBarberos extends AsyncNotifier<List<ModeloBarbero>> {
  @override
  FutureOr<List<ModeloBarbero>> build() async {
    return ref.read(repositorioAdministracionProvider).obtenerBarberos();
  }

  Future<void> invitarBarbero({
    required String email,
    required String sucursalId,
    required List<String> especialidades,
  }) async {
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioAdministracionProvider).invitarBarbero(
        email: email,
        sucursalId: sucursalId,
        especialidades: especialidades,
      );
      // Recargar la lista completa de barberos para obtener la información de perfil
      return ref.read(repositorioAdministracionProvider).obtenerBarberos();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> actualizarEstadoBarbero(String barberoId, bool activo) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAdministracionProvider)
          .actualizarEstadoBarbero(barberoId, activo);
      return listaAnterior
          .map((b) => b.id == barberoId ? b.copyWith(activo: activo) : b)
          .toList();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorBarberosProvider =
    AsyncNotifierProvider<ControladorBarberos, List<ModeloBarbero>>(() {
      return ControladorBarberos();
    });
