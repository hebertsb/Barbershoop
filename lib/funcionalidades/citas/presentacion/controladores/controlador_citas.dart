import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_citas.dart';
import '../../dominio/modelo_cita.dart';

class ControladorCitas
    extends AutoDisposeFamilyAsyncNotifier<List<ModeloCita>, String> {
  @override
  FutureOr<List<ModeloCita>> build(String arg) {
    return ref.read(repositorioCitasProvider).obtenerCitasDelDia(arg);
  }

  Future<void> marcarNoAsistio(String citaId) async {
    state = const AsyncLoading<List<ModeloCita>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioCitasProvider).marcarNoAsistio(citaId);
      return ref.read(repositorioCitasProvider).obtenerCitasDelDia(arg);
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorCitasProvider = AsyncNotifierProvider.autoDispose
    .family<ControladorCitas, List<ModeloCita>, String>(ControladorCitas.new);