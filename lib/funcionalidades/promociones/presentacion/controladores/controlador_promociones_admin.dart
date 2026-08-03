import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_promociones.dart';
import '../../dominio/modelo_promocion.dart';

class ControladorPromocionesAdmin extends AsyncNotifier<List<ModeloPromocion>> {
  @override
  FutureOr<List<ModeloPromocion>> build() async {
    return ref
        .read(repositorioPromocionesProvider)
        .obtenerTodasLasPromociones();
  }

  Future<void> guardar(ModeloPromocion promocion) async {
    state = const AsyncLoading<List<ModeloPromocion>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioPromocionesProvider)
          .guardarPromocion(promocion);
      return ref
          .read(repositorioPromocionesProvider)
          .obtenerTodasLasPromociones();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> cambiarEstado({
    required String promocionId,
    required bool activo,
  }) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloPromocion>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioPromocionesProvider)
          .cambiarEstadoPromocion(promocionId: promocionId, activo: activo);
      return listaAnterior.map<ModeloPromocion>((p) {
        if (p.id == promocionId) {
          return p.copyWith(activo: activo);
        }
        return p;
      }).toList();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> eliminar(String promocionId) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloPromocion>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioPromocionesProvider)
          .eliminarPromocion(promocionId);
      return listaAnterior.where((p) => p.id != promocionId).toList();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorPromocionesAdminProvider =
    AsyncNotifierProvider<ControladorPromocionesAdmin, List<ModeloPromocion>>(
      ControladorPromocionesAdmin.new,
    );