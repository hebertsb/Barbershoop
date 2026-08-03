import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reservas/datos/repositorio_reservas.dart';
import '../../datos/repositorio_citas.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../dominio/modelo_cita.dart';

class ControladorMisCitas extends AsyncNotifier<List<ModeloCita>> {
  @override
  FutureOr<List<ModeloCita>> build() async {
    return ref.read(repositorioCitasProvider).obtenerMisCitas();
  }

  Future<void> cancelar(String citaId) async {
    state = const AsyncLoading<List<ModeloCita>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioReservasProvider).cancelarCita(citaId);
      return ref.read(repositorioCitasProvider).obtenerMisCitas();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorMisCitasProvider =
    AsyncNotifierProvider<ControladorMisCitas, List<ModeloCita>>(
      ControladorMisCitas.new,
    );

/// Cita futura `pendiente`/`confirmada` ms cercana en el tiempo, o `null`
/// si no hay ninguna que califique -- usada por la tarjeta "Prxima cita"
/// del dashboard del cliente.
final proximaCitaProvider = Provider<ModeloCita?>((ref) {
  final citas = ref.watch(controladorMisCitasProvider).value ?? [];
  final ahora = DateTime.now();

  final candidatas =
      citas
          .where(
            (c) =>
                c.fechaHora.isAfter(ahora) &&
                (c.estado == EstadoCita.pendiente ||
                    c.estado == EstadoCita.confirmada),
          )
          .toList()
        ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

  return candidatas.isEmpty ? null : candidatas.first;
});
