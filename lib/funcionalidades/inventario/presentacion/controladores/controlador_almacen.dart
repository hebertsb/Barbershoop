import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_inventario.dart';
import '../../dominio/modelo_insumo.dart';

class ControladorAlmacen
    extends AutoDisposeFamilyAsyncNotifier<List<ModeloInsumo>, String> {
  @override
  FutureOr<List<ModeloInsumo>> build(String arg) async {
    return ref
        .read(repositorioInventarioProvider)
        .obtenerInsumosDeSucursal(arg);
  }

  Future<void> guardarInsumo(ModeloInsumo insumo) async {
    state = const AsyncLoading<List<ModeloInsumo>>();
    state = await AsyncValue.guard(() async {
      final guardado = await ref
          .read(repositorioInventarioProvider)
          .guardarInsumo(insumo);
      final listaAnterior = state.value ?? [];
      final indice = listaAnterior.indexWhere((e) => e.id == guardado.id);
      if (indice != -1) {
        return List<ModeloInsumo>.from(listaAnterior)..[indice] = guardado;
      } else {
        final nuevaLista = [...listaAnterior, guardado];
        nuevaLista.sort((a, b) => a.nombre.compareTo(b.nombre));
        return nuevaLista;
      }
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> eliminarInsumo(String insumoId) async {
    state = const AsyncLoading<List<ModeloInsumo>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioInventarioProvider).eliminarInsumo(insumoId);
      return ref
          .read(repositorioInventarioProvider)
          .obtenerInsumosDeSucursal(arg);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> asignarABarbero({
    required String insumoId,
    required String barberoId,
    required int cantidad,
  }) async {
    state = const AsyncLoading<List<ModeloInsumo>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioInventarioProvider)
          .asignarInsumoABarbero(
            insumoId: insumoId,
            barberoId: barberoId,
            cantidad: cantidad,
          );
      return ref
          .read(repositorioInventarioProvider)
          .obtenerInsumosDeSucursal(arg);
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorAlmacenProvider = AsyncNotifierProvider.autoDispose
    .family<ControladorAlmacen, List<ModeloInsumo>, String>(
      ControladorAlmacen.new,
    );
