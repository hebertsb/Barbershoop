import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_resenas.dart';

/// `true` si la cita ya tiene resea del cliente autenticado -- `family`
/// por `citaId` porque `TarjetaMiCita` consulta una por cada cita
/// `completada` visible en la lista.
class ControladorResenaDeCita extends FamilyAsyncNotifier<bool, String> {
  @override
  FutureOr<bool> build(String citaId) async {
    return ref.read(repositorioResenasProvider).citaYaTieneResena(citaId);
  }

  Future<void> calificar({
    required int calificacion,
    String? comentario,
  }) async {
    state = const AsyncLoading<bool>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioResenasProvider)
          .calificarCita(
            citaId: arg,
            calificacion: calificacion,
            comentario: comentario,
          );
      return true;
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorResenaDeCitaProvider =
    AsyncNotifierProvider.family<ControladorResenaDeCita, bool, String>(
      ControladorResenaDeCita.new,
    );
