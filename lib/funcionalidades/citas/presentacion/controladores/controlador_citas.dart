import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_citas.dart';
import '../../dominio/modelo_cita.dart';

/// Citas del día de una sucursal (agenda del barbero/secretaria) --
/// `family` por [sucursalId] porque el admin/secretaria puede cambiar de
/// sucursal sin perder el caché de las demás.
class ControladorCitas extends FamilyAsyncNotifier<List<ModeloCita>, String> {
  @override
  FutureOr<List<ModeloCita>> build(String sucursalId) async {
    return ref.read(repositorioCitasProvider).obtenerCitasDelDia(sucursalId);
  }

  Future<void> marcarNoAsistio(String citaId) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloCita>>();
    state = await AsyncValue.guard(() async {
      final actualizada = await ref
          .read(repositorioCitasProvider)
          .marcarNoAsistio(citaId);
      return listaAnterior
          .map((c) => c.id == citaId ? actualizada : c)
          .toList();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorCitasProvider =
    AsyncNotifierProvider.family<ControladorCitas, List<ModeloCita>, String>(
      ControladorCitas.new,
    );
