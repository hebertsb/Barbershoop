import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../datos/repositorio_actualizacion.dart';
import '../../dominio/modelo_version_app.dart';

/// Convierte una versión `"1.2.3"` en sus componentes enteros
/// `[1, 2, 3]`. Componentes no numéricos (formato inesperado) se toman
/// como `0` en vez de romper la comparación.
List<int> _componentesVersion(String version) {
  return version
      .split('.')
      .map((parte) => int.tryParse(parte.trim()) ?? 0)
      .toList();
}

/// Compara la versión instalada contra la versión remota (última fila de
/// `versiones_app`) componente por componente (no como texto: comparar
/// strings da resultados incorrectos, ej. `"1.10.0" < "1.9.0"`).
///
/// Devuelve `true` cuando [instalada] es estrictamente menor que [remota].
/// Si tienen distinta cantidad de componentes (ej. `"1.0"` vs `"1.0.0"`) los
/// que faltan se completan con `0`.
bool versionInstaladaDesactualizada(String instalada, String remota) {
  final partesInstalada = _componentesVersion(instalada);
  final partesRemota = _componentesVersion(remota);
  final cantidad = partesInstalada.length > partesRemota.length
      ? partesInstalada.length
      : partesRemota.length;

  for (var i = 0; i < cantidad; i++) {
    final componenteInstalada = i < partesInstalada.length
        ? partesInstalada[i]
        : 0;
    final componenteRemota = i < partesRemota.length ? partesRemota[i] : 0;
    if (componenteInstalada != componenteRemota) {
      return componenteInstalada < componenteRemota;
    }
  }
  return false;
}

/// Chequeo de actualización disponible, "best effort": cualquier fallo (sin
/// conexión al abrir la app, tabla `versiones_app` vacía, `PackageInfo` no
/// disponible, etc.) se traga en silencio y se resuelve como "no hay
/// actualización" en vez de romper el arranque de la app.
///
/// Devuelve `null` si no aplica mostrar el diálogo de actualización, o el
/// [ModeloVersionApp] remoto si la versión instalada está desactualizada.
final controladorActualizacionProvider = FutureProvider<ModeloVersionApp?>((
  ref,
) async {
  try {
    final ultima = await ref
        .read(repositorioActualizacionProvider)
        .obtenerUltimaVersion();
    if (ultima == null) return null;

    final infoInstalada = await PackageInfo.fromPlatform();
    if (versionInstaladaDesactualizada(infoInstalada.version, ultima.version)) {
      return ultima;
    }
    return null;
  } catch (_) {
    return null;
  }
});