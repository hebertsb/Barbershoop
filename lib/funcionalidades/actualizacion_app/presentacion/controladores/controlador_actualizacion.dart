import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../datos/repositorio_actualizacion.dart';
import '../../dominio/modelo_version_app.dart';

/// Compara versiones semánticas ("1.2.3") componente a componente,
/// completando con 0 los que falten cuando difiere la cantidad de partes.
/// `true` = la instalada es estrictamente menor que la remota.
bool versionInstaladaDesactualizada(String instalada, String remota) {
  final partesInstalada = instalada.split('.').map(int.parse).toList();
  final partesRemota = remota.split('.').map(int.parse).toList();
  final maxLen = partesInstalada.length > partesRemota.length
      ? partesInstalada.length
      : partesRemota.length;

  for (var i = 0; i < maxLen; i++) {
    final a = i < partesInstalada.length ? partesInstalada[i] : 0;
    final b = i < partesRemota.length ? partesRemota[i] : 0;
    if (a != b) return a < b;
  }
  return false;
}

class ControladorActualizacion extends AsyncNotifier<ModeloVersionApp?> {
  @override
  FutureOr<ModeloVersionApp?> build() async {
    final version = await ref
        .read(repositorioActualizacionProvider)
        .obtenerUltimaVersion();
    if (version == null) return null;

    final infoInstalada = await PackageInfo.fromPlatform();
    final desactualizada = versionInstaladaDesactualizada(
      infoInstalada.version,
      version.version,
    );
    return desactualizada ? version : null;
  }
}

final controladorActualizacionProvider =
    AsyncNotifierProvider<ControladorActualizacion, ModeloVersionApp?>(
      ControladorActualizacion.new,
    );
