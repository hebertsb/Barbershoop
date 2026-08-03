import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_accesos_admin.dart';
import '../../dominio/catalogo_accesos_admin.dart';

/// Accesos rápidos del dashboard admin (máximo 4), elegidos según qué
/// secciones usó MÁS el admin autenticado en los últimos 30 días -- ver
/// `elegirAccesosRapidos` (dominio puro y testeable) para el criterio
/// exacto de selección/relleno.
class ControladorAccesoRapidoAdmin extends AsyncNotifier<List<AccesoAdmin>> {
  @override
  FutureOr<List<AccesoAdmin>> build() async {
    final rutasTop = await ref
        .read(repositorioAccesosAdminProvider)
        .obtenerRutasTopAccesos(limite: 4);
    return elegirAccesosRapidos(rutasTop, maximo: 4);
  }
}

final controladorAccesoRapidoAdminProvider =
    AsyncNotifierProvider<ControladorAccesoRapidoAdmin, List<AccesoAdmin>>(
      () {
        return ControladorAccesoRapidoAdmin();
      },
    );