import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_servicio.dart';

class ControladorServicios extends AsyncNotifier<List<ModeloServicio>> {
  @override
  FutureOr<List<ModeloServicio>> build() async {
    return ref.read(repositorioAdministracionProvider).obtenerServicios();
  }

  Future<void> guardarServicio(ModeloServicio servicio) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloServicio>>();
    state = await AsyncValue.guard(() async {
      final guardada =
          await ref
              .read(repositorioAdministracionProvider)
              .guardarServicio(servicio);
      final indice = listaAnterior.indexWhere((e) => e.id == guardada.id);
      if (indice != -1) {
        return List<ModeloServicio>.from(listaAnterior)..[indice] = guardada;
      } else {
        final nuevaLista = [...listaAnterior, guardada];
        nuevaLista.sort((a, b) => a.nombre.compareTo(b.nombre));
        return nuevaLista;
      }
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorServiciosProvider =
    AsyncNotifierProvider<ControladorServicios, List<ModeloServicio>>(() {
      return ControladorServicios();
    });
