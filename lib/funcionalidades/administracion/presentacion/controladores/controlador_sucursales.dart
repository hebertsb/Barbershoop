import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_sucursal.dart';

class ControladorSucursales extends AsyncNotifier<List<ModeloSucursal>> {
  @override
  FutureOr<List<ModeloSucursal>> build() async {
    return ref.read(repositorioAdministracionProvider).obtenerSucursales();
  }

  Future<void> guardarSucursal(ModeloSucursal sucursal) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloSucursal>>();
    state = await AsyncValue.guard(() async {
      final guardada =
          await ref
              .read(repositorioAdministracionProvider)
              .guardarSucursal(sucursal);
      final indice = listaAnterior.indexWhere((e) => e.id == guardada.id);
      if (indice != -1) {
        return List<ModeloSucursal>.from(listaAnterior)..[indice] = guardada;
      } else {
        final nuevaLista = [...listaAnterior, guardada];
        nuevaLista.sort((a, b) => a.nombre.compareTo(b.nombre));
        return nuevaLista;
      }
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorSucursalesProvider =
    AsyncNotifierProvider<ControladorSucursales, List<ModeloSucursal>>(() {
      return ControladorSucursales();
    });
